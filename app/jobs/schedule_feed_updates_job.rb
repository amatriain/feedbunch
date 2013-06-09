class ScheduleFeedUpdatesJob
  @queue = :update_feeds

  ##
  # When this job is run, it schedules updates of the passed feed to be run each hour.
  #
  # Receives as argument the id of the feed which updates are to be scheduled.
  #
  # This job is intended to be run once for a given feed. It is part of the mechanism that delays the first run of
  # an update job a random time between zero and 60 minutes. After that each update is run one hour after the last
  # update; this means that updates will be more or less randomly spread during each hour. This helps reducing load at
  # a given moment.

  def self.perform(feed_id)
    if Feed.exists? feed_id
      name = "update_feed_#{feed_id}"
      config = {}
      config[:class] = 'UpdateFeedJob'
      config[:args] = feed_id
      config[:every] = '1h'

      Rails.logger.info "Scheduling updates of feed #{feed_id} every hour"
      Resque.enqueue UpdateFeedJob, feed_id
      Resque.set_schedule name, config
    else
      Rails.logger.warn "Feed #{feed_id} scheduled for its first update does not exist (maybe it's been deleted?)"
    end
  end
end