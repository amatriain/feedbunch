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
  # Note.- This methods relies on the schedule to run updates for a feed being named "update_feed_#{feed.id}". If this
  # naming scheme ever changes, this method will have to be changed accordingly.

  def self.fix_update_schedules
    Rails.logger.debug 'Fixing feed update schedules'
    feeds_unscheduled = []

    # examine only feeds older than 90 minutes
    Feed.all.each do |feed|
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