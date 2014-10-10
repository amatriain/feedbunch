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
    feeds_unscheduled = []

    Feed.where(available: true).each do |feed|
      # get update schedule for the feed
      schedule_present = feed_schedule_present? feed.id
      Rails.logger.debug "Update schedule for feed #{feed.id}  #{feed.title} present?: #{schedule_present}"

      # if a feed has no update schedule, add it to the array of feeds to be fixed
      if !schedule_present
        Rails.logger.warn "Missing schedule for feed #{feed.id} - #{feed.title}"
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
    set_scheduled_update feed_id, delay.minutes, remove_other_schedules: false
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
    Rails.logger.info "Feed #{feed_id} update scheduled #{queue_jobs.size} times, deleting" if scheduled_job.size > 0
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

    # Decrement the update interval saved in the database
    Rails.logger.debug "Decrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually decrement the update interval in Resque
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

    # Increment the update interval saved in the database
    Rails.logger.debug "Incrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually increment the update interval in Resque
    set_scheduled_update feed.id, feed.fetch_interval_secs
  end

  private

  ##
  # Set a scheduled update for a feed.
  #
  # Optionally if the feed already has a scheduled update,
  # it is unscheduled. This guarantees that each feed
  # has at most one update scheduled in the future.
  #
  # Receives as arguments:
  # - ID of the feed that will be updated
  # - in_seconds: number of seconds until the update runs
  # - optionally, a boolean that indicates whether to remove other scheduled updates set for the feed.
  # If we are sure that no other updates are scheduled, a false should be passed to this argument
  # for performance reasons. True by default.

  def self.set_scheduled_update(feed_id, in_seconds, remove_other_schedules: true)
    if remove_other_schedules
      Rails.logger.info "Checking if feed #{feed_id} has an update already scheduled"
      scheduled = feed_schedule_present? feed_id
      unschedule_feed_updates feed_id if scheduled
    end

    Rails.logger.info "Setting scheduled update of feed #{feed_id} in #{in_seconds} seconds"
    ScheduledUpdateFeedWorker.perform_in in_seconds.seconds, feed_id
  end

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
    ScheduledUpdateFeedWorker.perform_at perform_at
  end

  ##
  # Check if the passed feed's scheduled updates have been set.
  #
  # Receives as argument a feed id.
  #
  # To check if the feed updates have been scheduled, the following Sidekiq queues are checked:
  # - The named "update_feeds" queue. The worker will be found there when its scheduled run time comes, until
  # a Sidekiq thread is free to process it.
  # - The queue with jobs scheduled to run in the future
  # - The queue of jobs that have failed (an error has raised during processing) and are scheduled to be retried in
  # the future
  # - The currently running jobs
  #
  # If a ScheduledFeedUpdateWorker is found in any of these queues with the id of the passed feed as argument,
  # a boolean true is returned. Otherwise false is returned.

  def self.feed_schedule_present?(feed_id)
    queued = feed_update_queued? feed_id
    scheduled = feed_update_scheduled? feed_id
    retrying = feed_update_retrying? feed_id
    running = feed_update_running? feed_id

    present = (queued || scheduled || retrying || running)

    if present
      Rails.logger.info "Feed #{feed_id} update worker is present"
    else
      Rails.logger.info "Feed #{feed_id} update worker is not present"
    end

    return present
  end

  ##
  # Check if a scheduled update for the passed feed is already in the 'update_feeds' queue waiting
  # for a free Sidekiq thread to be processed.
  #
  # Receives as argument a feed id.
  #
  # Returns true if the update is already queued, false otherwise.

  def self.feed_update_queued?(feed_id)
    queue = Sidekiq::Queue.new 'update_feeds'
    queued = queue.any? {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}

    if queued
      Rails.logger.info "Feed #{feed_id} update worker queued for immediate processing"
    else
      Rails.logger.info "Feed #{feed_id} update worker not queued for immediate processing"
    end

    return queued
  end

  ##
  # Check if an update for the passed feed is scheduled.
  #
  # Receives as argument a feed id.
  #
  # Returns true if the update is scheduled, false otherwise.

  def self.feed_update_scheduled?(feed_id)
    scheduled_set = Sidekiq::ScheduledSet.new
    scheduled = scheduled_set.any? {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}

    if scheduled
      Rails.logger.info "Feed #{feed_id} update worker scheduled"
    else
      Rails.logger.info "Feed #{feed_id} update worker not scheduled"
    end

    return scheduled
  end

  ##
  # Check if an update for the passed feed has failed and is scheduled for retrying.
  #
  # Receives as argument a feed id.
  #
  # Returns true if the update is going to be retried, false otherwise.

  def self.feed_update_retrying?(feed_id)
    retrySet = Sidekiq::RetrySet.new
    retrying = retrySet.any? {|job| job.klass == 'ScheduledUpdateFeedWorker' && job.args[0] == feed_id}

    if retrying
      Rails.logger.info "Feed #{feed_id} update worker scheduled for retrying"
    else
      Rails.logger.info "Feed #{feed_id} update worker not scheduled for retrying"
    end

    return retrying
  end

  ##
  # Check if an update for the passed feed is currently being processed.
  #
  # Receives as argument a feed id.
  #
  # Returns true if the update is currently running, false otherwise.

  def self.feed_update_running?(feed_id)
    workers = Sidekiq::Workers.new
    running = workers.any? do |process_id, thread_id, work|
      work['payload']['class'] == 'ScheduledUpdateFeedWorker' && work['payload']['args'][0] == feed_id
    end

    if running
      Rails.logger.info "Feed #{feed_id} update worker currently running"
    else
      Rails.logger.info "Feed #{feed_id} update worker currently not running"
    end

    return running
  end
end

