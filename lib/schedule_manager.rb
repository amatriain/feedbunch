##
# Class with methods related to managing resque schedules.

class ScheduleManager

  ##
  # For each feed in the database, ensure that resque-schedule has a scheduled update for the feed.
  #
  # If a feed is found with no scheduled update, a job is scheduled to update the feed periodically.
  #
  # After invoking this method all feeds have scheduled updates that run every hour.
  #
  # Feeds created less than 1h30m ago are ignored by this method. Feeds normally get their updates scheduled
  # inside the first hour after they are first saved in the database; however the actual time could be over an hour
  # if the job queue is saturated. A feed without scheduled updates that was created less than 90 minutes ago probably
  # still hasn't had its updates scheduled (ScheduleFeedUpdatesJob has not yet run for this feed), and can be ignored
  # safely, at least until it's older than 90 minutes.
  #
  # Note.- This methods relies on the schedule to run updates for a feed being named "update_feed_#{feed.id}". If this
  # naming scheme ever changes, this method will have to be changed accordingly.

  def self.fix_update_schedules
    Rails.logger.debug 'Fixing feed update schedules'
    feeds_unscheduled = []

    # examine only feeds older than 90 minutes
    Feed.where('created_at < ?', Time.now - 90.minutes).each do |feed|
      # get update schedule for the feed
      schedule = Resque.get_schedule "update_feed_#{feed.id}"
      Rails.logger.debug "Update schedule for feed #{feed.id}  #{feed.title}: #{schedule}"
      # if a feed has no update schedule, add it to the array
      if schedule == nil
        Rails.logger.warn "Missing schedule for feed #{feed.id} - #{feed.title}"
        feeds_unscheduled << feed
      end
    end

    if feeds_unscheduled.length > 0
      Rails.logger.warn "A total of #{feeds_unscheduled.length} feeds are missing their update schedules. Adding missing schedules."
      feeds_unscheduled.each do |feed|
        Rails.logger.warn "Adding missing update schedule for feed #{feed.id} - #{feed.title}"
        UpdateFeedJob.schedule_feed_updates feed.id
      end
    end
  end
end