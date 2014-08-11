require 'subscriptions_manager'
require 'schedule_manager'

##
# Background job for scheduled updates to a feed.
#
# Its perform method will be invoked from a Resque worker.

class ScheduledUpdateFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # If the feed does not exist, further refreshes of the feed are unscheduled. This keeps deleted
  # feeds from having scheduled updates.
  #
  # Every time a feed update runs the unread entries count for each subscribed user are recalculated and corrected if necessary.
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

    # Check that feed has not been marked as unavailable
    if !feed.available
      Rails.logger.warn "Feed #{feed_id} scheduled to be updated, but it has been marked as unavailable. Unscheduling further updates."
      ScheduleManager.unschedule_feed_updates feed_id
      return
    end

    Rails.logger.debug "Updating feed #{feed.id} - #{feed.title}"

    # Initialize the number of entries in the feed before and after fetching, so the variables can be
    # used in the ensure clause even if an error is raised while fetching (e.g. the server responds
    # with a HTTP error code)
    entries_before = feed.entries.count
    entries_after = 0

    begin
      # Fetch feed
      FeedClient.fetch feed
    rescue RestClient::Exception,
      RestClient::RequestTimeout,
      SocketError,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError => e

      # If fetching from fetch_url fails, try to perform autodiscovery (download the HTML document at feed.url and
      # attempt to get a <link> element pointing to a feed from its <head>; this should be the current fetch_url).
      # This is intended for the case in which the owner of a feed changes its URL (e.g. migrating from a custom solution
      # to feedburner) but the website itself is still available at the old URL. This happens often. Feedbunch attempts
      # to autocorrect the situation, as long as autodiscovery is enabled.
      FeedClient.fetch feed, true
    end

    entries_after = feed.entries.count

    # If the update didn't fail, mark the feed as "not currently failing"
    feed.update failing_since: nil if !feed.failing_since.nil?

    # Delete entries that are too old
    OldEntriesCleaner.cleanup feed

  rescue RestClient::Exception,
      RestClient::RequestTimeout,
      SocketError,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError => e
    # all these errors mean the feed cannot be updated, but the job itself has not failed. Do not re-raise the error
    if feed.present?
      # If this is the first update that fails, save the date&time the feed started failing
      feed.update failing_since: Time.zone.now if feed.failing_since.nil?

      # If the feed has been failing for too long, mark it as unavailable
      if Time.zone.now - feed.failing_since > Feedbunch::Application.config.unavailable_after
        feed.update available: false
      end
    end

    Rails.logger.error "Error fetching feed #{feed_id} - #{feed.try :fetch_url}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
  ensure
    if feed.present? && feed.try(:available)
      # Update timestamp of the last time the feed was fetched
      Rails.logger.debug "Updating time of last update for feed #{feed.id} - #{feed.title}"
      feed.update! last_fetched: Time.zone.now

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