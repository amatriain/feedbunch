class UpdateFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(feed_id)
    FeedClient.fetch feed_id, false
  end

  ##
  # Schedule updating of a feed using Resque-scheduler.
  # Receives as argument the id of the feed which update is to be scheduled.
  #
  # There can only be one scheduled job for updates of a given feed. If there is a scheduled update
  # job for a feed and this method is invoked with the id of that feed, the old schedule is updated.
  #
  # Scheduled jobs are named "update_feed_[feed_id]", they can be monitored using the Resque web console.
  #
  # The first run of a job is scheduled to happen a random amount of minutes, between 0 and 60, after this
  # method is invoked. After that the job is run every hour. This is done so that feed updates are more or less
  # evenly, or at least randomly, spaced in time. This way the server load from the updates is spaced over
  # time, to affect user experience as little as possible.

  def self.schedule_feed_updates(feed_id)
    delay = Random.rand 61
    Rails.logger.info "Scheduling updates of feed #{feed_id} every hour, starting #{delay} minutes from now at #{Time.now + delay.minutes}"
    Resque.enqueue_in delay.minutes, ScheduleFeedUpdatesJob, feed_id
  end

  ##
  # Unschedule (this is, remove from scheduling) the update feed job for the passed feed.
  # Receives as argument the id of the feed which update is to be unscheduled.
  #
  # After invoking this method, an update job for this feed will never be enqueued again (at least while
  # UpdateFeedJob.schedule_feed_updates is not invoked for this feed).

  def self.unschedule_feed_updates(feed_id)
    Rails.logger.info "Unscheduling updates of feed #{feed_id}"
    Resque.remove_schedule "update_feed_#{feed_id}"
  end
end