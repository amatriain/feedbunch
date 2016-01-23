##
# Class with methods related to managing update schedules.

class ScheduleManager

  ##
  # For each available feed in the database, ensure that the next update of the feed is scheduled
  #
  # If a feed is found with no scheduled update, one is added.
  #
  # After invoking this method all available feeds are guaranteed to have their next update scheduled.

  def self.fix_scheduled_updates
    Rails.logger.debug 'Fixing scheduled feed updates'

    queue = Sidekiq::Queue.new 'update_feeds'
    queued_ids = queue.select{|job| job.klass == 'ScheduledUpdateFeedWorker'}.map{|job| job.args[0]}

    scheduled_set = Sidekiq::ScheduledSet.new
    scheduled_ids = scheduled_set.select{|job| job.klass == 'ScheduledUpdateFeedWorker'}.map{|job| job.args[0]}

    retrySet = Sidekiq::RetrySet.new
    retry_ids = retrySet.select{|job| job.klass == 'ScheduledUpdateFeedWorker'}.map{|job| job.args[0]}

    workers = Sidekiq::Workers.new
    worker_ids = workers.select{|process_id, thread_id, work| work['payload']['class'] == 'ScheduledUpdateFeedWorker'}.map{|process_id, thread_id, work| work['payload']['args'][0]}

    feeds_unscheduled = []

    Feed.where(available: true).find_each do |feed|
      # count how many update workers there are for each feed in Sidekiq
      schedule_count = feed_schedule_count feed.id, queued_ids, scheduled_ids, retry_ids, worker_ids
      Rails.logger.debug "Update schedule for feed #{feed.id}  #{feed.title} present #{schedule_count} times"

      # if a feed has no update schedule, add it to the array of feeds to be fixed
      if schedule_count == 0
        Rails.logger.warn "Missing schedule for feed #{feed.id} - #{feed.title}"
        feeds_unscheduled << feed
      elsif schedule_count > 1
        # there should be one scheduled update for each feed.
        # If a feed has more than one scheduled update, remove all updates for the feed and add it to the array of feeds to be fixed
        Rails.logger.warn "Feed #{feed.id} - #{feed.title} is scheduled more than one time, removing all scheduled updates to re-add just one"
        unschedule_feed_updates feed.id
        feeds_unscheduled << feed
      end
    end

    if feeds_unscheduled.length > 0
      Rails.logger.warn "A total of #{feeds_unscheduled.length} feeds are missing their update schedules. Adding missing schedules."
      feeds_unscheduled.each do |feed|
        add_missing_schedule feed
      end
    end
  end

  ##
  # Schedule the first update of a feed.
  # Receives as argument the id of the feed for which its first update will be scheduled.
  #
  # The update is scheduled to run in a random amount of minutes, between 0 and 60, after this
  # method is invoked. This is done so that feed updates are more or less
  # evenly, or at least randomly, spaced in time. This way the server load from the updates is spaced over
  # time, to affect user experience as little as possible.
  #
  # After each update, the worker schedules the next update of the feed. The worker tries to adapt
  # the scheduling to the rate at which new entries appear in the feed.

  def self.schedule_first_update(feed_id)
    delay = Random.rand 61
    Rails.logger.info "Scheduling updates of feed #{feed_id} every hour, starting #{delay} minutes from now at #{Time.zone.now + delay.minutes}"
    set_scheduled_update feed_id, delay.minutes
  end

  ##
  # Unschedule (this is, remove from scheduling) future updates of the passed feed.
  # Receives as argument the id of the feed; scheduled updates for other feeds are unaffected.
  #
  # Normally when this method is invoked the feed is also have to be marked as unavailable.
  # After invoking this method, if the feed is marked as unavailable, it won't be updated again.
  # However if it's marked as available the next time FixSchedulesWorker runs (normally daily),
  # periodic updates will start running again. Because of this, if we really want a feed to
  # stop updating it's not enough to invoke this method, the "available" flag of the feed
  # must be set to false as well.

  def self.unschedule_feed_updates(feed_id)
    Rails.logger.info "Unscheduling updates of feed #{feed_id}"

    queue = Sidekiq::Queue.new 'update_feeds'
    queue_jobs = queue.select {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}
    Rails.logger.info "Feed #{feed_id} update found in 'update_feeds' queue #{queue_jobs.size} times, deleting" if queue_jobs.size > 0
    queue_jobs.each {|job| job.delete}

    scheduled_set = Sidekiq::ScheduledSet.new
    scheduled_job = scheduled_set.select {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}
    Rails.logger.info "Feed #{feed_id} update scheduled #{scheduled_job.size} times, deleting" if scheduled_job.size > 0
    scheduled_job.each {|job| job.delete}

    retrying = Sidekiq::RetrySet.new
    retrying_job = retrying.select {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}
    Rails.logger.info "Feed #{feed_id} update marked for retrying #{retrying_job.size} times, deleting" if retrying_job.size > 0
    retrying_job.each {|job| job.delete}
  end

  ##
  # Decrement the interval between updates of the passed feed.
  # The current interval is decremented by 10% up to the minimum set in
  # the application configuration.

  def self.decrement_update_interval(feed)
    new_interval = (feed.fetch_interval_secs * 0.9).round
    min = Feedbunch::Application.config.min_update_interval
    new_interval = min if new_interval < min

    # Add up to +/- 1 minute to the update interval, to add some entropy and distribute updates more evenly over time.
    entropy = schedule_entropy
    new_interval += entropy.seconds

    # Decrement the update interval saved in the database
    Rails.logger.debug "Decrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually decrement the update interval
    set_scheduled_update feed.id, feed.fetch_interval_secs
  end

  ##
  # Increment the interval between updates of the passed feed.
  # The current interval is incremented by 10% up to the maximum set in
  # the application configuration.

  def self.increment_update_interval(feed)
    new_interval = (feed.fetch_interval_secs * 1.1).round
    max = Feedbunch::Application.config.max_update_interval
    new_interval = max if new_interval > max

    # Add up to +/- 1 minute to the update interval, to add some entropy and distribute updates more evenly over time.
    entropy = schedule_entropy
    new_interval += entropy.seconds

    # Increment the update interval saved in the database
    Rails.logger.debug "Incrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually increment the update interval
    set_scheduled_update feed.id, feed.fetch_interval_secs
  end

  ##
  # Return a random number between -60 and 60.
  # It can be used (as seconds) to add some entropy to schedules, so that scheduled updates are more evenly distributed.

  def self.schedule_entropy
    return Random.rand(121) - 60
  end
  private_class_method :schedule_entropy

  ##
  # Set a scheduled update for a feed.
  #
  # Receives as arguments:
  # - ID of the feed that will be updated
  # - in_seconds: number of seconds until the update runs

  def self.set_scheduled_update(feed_id, in_seconds)
    Rails.logger.info "Setting scheduled update of feed #{feed_id} in #{in_seconds} seconds"
    ScheduledUpdateFeedWorker.perform_in in_seconds.seconds, feed_id
  end
  private_class_method :set_scheduled_update

  ##
  # Add a missing update schedule for a feed. Receives the feed as argument.
  # The next update will be scheduled to run at fetch_interval_secs seconds after last_fetched, as if the schedule
  # had not disappeared, unless that time has already passed, in which case it will be scheduled immediately.

  def self.add_missing_schedule(feed)
    Rails.logger.warn "Adding missing update schedule for feed #{feed.id} - #{feed.title}"

    if feed.last_fetched.blank?
      # If feed has never been fetched, schedule its first update sometime in the next hour
      delay = Random.rand 61
      perform_at = Time.zone.now + delay.minutes
    else
      # Calculate when should the update happen, based on the last time the feed was updated
      # and its current feed interval.
      perform_at = feed.last_fetched + feed.fetch_interval_secs.seconds
    end

    # Schedule update. If the scheduled time is in the past (i.e. the feed should have been updated
    # in the past but it wasn't for some reason), Sidekiq will enqueue the job immediately.
    ScheduledUpdateFeedWorker.perform_at perform_at, feed.id
  end
  private_class_method :add_missing_schedule

  ##
  # Count how many scheduled updates are set for the passed feed.
  #
  # Receives as arguments:
  # - feed id
  # - array of IDs of feeds in the "update_feeds" queue
  # - array of IDs of feeds with a scheduled update
  # - array of IDs of feeds with updates marked for retrying
  # - array of IDs of feeds with updates currently running in a worker thread
  #
  # To count the number of feed updates that have been scheduled, the following Sidekiq queues passed as arguments are checked:
  # - The named "update_feeds" queue. The worker will be found there when its scheduled run time comes, until
  # a Sidekiq thread is free to process it.
  # - The queue with jobs scheduled to run in the future
  # - The queue of jobs that have failed (an error has raised during processing) and are scheduled to be retried in
  # the future
  # - The currently running jobs
  #
  # The number of times ScheduledFeedUpdateWorker is found in any of these queues with the id of the passed feed as argument
  # is counted and returned.

  def self.feed_schedule_count(feed_id, queued_ids, scheduled_ids, retry_ids, worker_ids)
    queued_count = update_queued_count feed_id, queued_ids
    scheduled_count = update_scheduled_count feed_id, scheduled_ids
    retrying_count = update_retrying_count feed_id, retry_ids
    running_count = update_running_count feed_id, worker_ids

    updates_count = queued_count + scheduled_count + retrying_count + running_count

    if updates_count > 0
      Rails.logger.info "Feed #{feed_id} update worker is present"
    else
      Rails.logger.info "Feed #{feed_id} update worker is not present"
    end

    return updates_count
  end
  private_class_method :feed_schedule_count

  ##
  # Count how many scheduled updates for the passed feed are already in the 'update_feeds' queue waiting
  # for a free Sidekiq thread to be processed.
  #
  # Receives as arguments:
  # - feed id
  # - array of IDs of feeds in the "update_feeds" queue
  #
  # Returns the count of scheduled updates, zero if none.

  def self.update_queued_count(feed_id, queued_ids)
    queued_count = queued_ids.count feed_id

    if queued_count > 0
      Rails.logger.info "Feed #{feed_id} update worker queued for immediate processing"
    else
      Rails.logger.info "Feed #{feed_id} update worker not queued for immediate processing"
    end

    return queued_count
  end
  private_class_method :update_queued_count

  ##
  # Count how many updates for the passed feed are scheduled.
  #
  # Receives as arguments:
  # - feed id
  # - array of IDs of feeds with a scheduled update
  #
  # Returns the count of scheduled updates for the passed feed, zero if none.

  def self.update_scheduled_count(feed_id, scheduled_ids)
    scheduled_count = scheduled_ids.count feed_id

    if scheduled_count > 0
      Rails.logger.info "Feed #{feed_id} update worker scheduled"
    else
      Rails.logger.info "Feed #{feed_id} update worker not scheduled"
    end

    return scheduled_count
  end
  private_class_method :update_scheduled_count

  ##
  # Count how many updates for the passed feed are scheduled for retrying.
  #
  # Receives as arguments:
  # - feed id
  # - array of IDs of feeds with updates marked for retrying
  #
  # Returns the count of updates scheduled for retrying, zero if none.

  def self.update_retrying_count(feed_id, retry_ids)
    retrying_count = retry_ids.count feed_id

    if retrying_count > 0
      Rails.logger.info "Feed #{feed_id} update worker scheduled for retrying"
    else
      Rails.logger.info "Feed #{feed_id} update worker not scheduled for retrying"
    end

    return retrying_count
  end
  private_class_method :update_retrying_count

  ##
  # Count how many updates for the passed feed are currently being processed.
  #
  # Receives as arguments:
  # - feed id
  # - array of IDs of feeds with updates currently running in a worker thread
  #
  # Returns the count of updates currently running, zero if no update for the passed feed is running.

  def self.update_running_count(feed_id, worker_ids)
    running_count = worker_ids.count feed_id

    if running_count > 0
      Rails.logger.info "Feed #{feed_id} update worker currently running"
    else
      Rails.logger.info "Feed #{feed_id} update worker currently not running"
    end

    return running_count
  end
  private_class_method :update_running_count
end

