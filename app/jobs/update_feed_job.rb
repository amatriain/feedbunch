require 'subscriptions_manager'
require 'schedule_manager'

##
# Background job to fetch and update a feed's entries.
#
# Its perform method will be invoked from a Resque worker.

class UpdateFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # If the feed does not exist, further refreshes of the feed are unscheduled. This avoids the case
  # in which scheduled updates for a deleted feed happened periodically.
  #
  # Every time a feed update runs the unread entries count for each subscribed user are recalculated and corrected if necessary
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(feed_id)
    # Check that feed actually exists
    if !Feed.exists? feed_id
      Rails.logger.warn "Feed #{feed_id} scheduled to be updated, but it does not exist in the database. Unscheduling further updates."
      ScheduleManager.unschedule_feed_updates feed_id
      return
    end
    feed = Feed.find feed_id

    # Initialize the number of entries in the feed before and after fetching, so the variables can be
    # used in the ensure clause even if an error is raised while fetching (e.g. the server responds
    # with a HTTP error code)
    entries_before = feed.entries.count
    entries_after = 0

    # Fetch feed
    FeedClient.fetch feed

    entries_after = feed.entries.count

    # If the update didn't fail, mark the feed as "not currently failing"
    feed.update failing_since: nil if !feed.failing_since.nil?

  rescue RestClient::Exception, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, EmptyResponseError, FeedAutodiscoveryError, FeedFetchError, FeedParseError => e
    # all these errors mean the feed cannot be updated, but the job itself has not failed. Do not re-raise the error
    if feed.present?
      # If this is the first update that fails, save the date&time the feed started failing
      feed.update failing_since: DateTime.now if feed.failing_since.nil?

      # If the feed has been failing for too long, mark it as unavailable
      if Time.zone.now - feed.failing_since > Feedbunch::Application.config.unavailable_after
        feed.update available: false
      end
    end

    Rails.logger.error "Error fetching feed #{feed_id} - #{feed.try :fetch_url}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
  ensure
    if feed.present?
      # Update timestamp of the last time the feed was fetched
      Rails.logger.debug "Updating time of last update for feed #{feed.id} - #{feed.title}"
      feed.update last_fetched: DateTime.now

      if entries_after > entries_before
        # If new entries have been fetched, decrement the fetch interval
        ScheduleManager.decrement_update_interval feed
      else
        # If no new entries have been fetched, increment the fetch interval
        ScheduleManager.increment_update_interval feed
      end

      # Update unread entries count for all subscribed users.
      feed.users.each do |user|
        SubscriptionsManager.recalculate_unread_count feed, user
      end
    end
  end
end