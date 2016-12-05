require 'subscriptions_manager'
require 'schedule_manager'
require 'old_entries_cleaner'

##
# Background job for scheduled updates to a feed.
#
# This is a Sidekiq worker

class ScheduledUpdateFeedWorker
  include Sidekiq::Worker

  sidekiq_options queue: :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # If the feed does not exist, further refreshes of the feed are unscheduled. This keeps deleted
  # feeds from having scheduled updates.
  #
  # Every time a feed update runs the unread entries count for each subscribed user are recalculated and corrected if necessary.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(feed_id)
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
      FeedClient.fetch feed
    rescue RestClient::Exception,
      RestClient::RequestTimeout,
      SocketError,
      Net::HTTPBadResponse,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      Zlib::GzipFile::Error,
      Zlib::DataError,
      OpenSSL::SSL::SSLError,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError => e

      if feed.failing_since.present? && Time.zone.now - feed.failing_since > Feedbunch::Application.config.autodiscovery_after
        # If fetching from fetch_url has been failing for longer than the configured autodiscovery_after value, try to
        # perform autodiscovery (download the HTML document at feed.url and
        # try to get a <link> element pointing to a feed from its <head>; this should be the current fetch_url).
        #
        # This is intended for the case in which the owner of a feed changes its URL (e.g. migrating from a custom solution
        # to feedburner) but the website itself is still available at the old URL. This happens often. Feedbunch attempts
        # to autocorrect the situation, as long as autodiscovery is enabled.
        #
        # Disable http caching so the most up to date version of the HTML is returned (in case an old version is
        # cached with the old RSS URL).
        FeedClient.fetch feed, http_caching: false, perform_autodiscovery: true
      else
        # If the feed has been failing for less than the configured autodiscovery_after value, re-raise the
        # error to be handled by the global rescue clause
        raise e
      end
    end

    if feed.present? && Feed.exists?(feed&.id)
      feed = feed.reload

      entries_after = feed.entries.count

      # If the update didn't fail, mark the feed as "not currently failing"
      feed.update failing_since: nil unless feed.failing_since.nil?

      # Delete entries that are too old
      OldEntriesCleaner.cleanup feed
    end

  rescue RestClient::Exception,
      RestClient::RequestTimeout,
      SocketError,
      Net::HTTPBadResponse,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      Zlib::GzipFile::Error,
      Zlib::DataError,
      OpenSSL::SSL::SSLError,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError => e
    # all these errors mean the feed cannot be updated, but the job itself has not failed. Do not re-raise the error
    if feed.present? && Feed.exists?(feed&.id)
      feed = feed.reload
      # If this is the first update that fails, save the date&time the feed started failing
      feed.update! failing_since: Time.zone.now if feed.failing_since.nil?

      # If the feed has been failing for too long, mark it as unavailable
      if Time.zone.now - feed.failing_since > Feedbunch::Application.config.unavailable_after
        feed.update! available: false
      end
    end

    Rails.logger.warn "Error during scheduled update of feed #{feed_id} - #{feed&.fetch_url}: #{e.message}"
  ensure
    if feed.present? && Feed.exists?(feed&.id) && feed&.available
      # Update timestamp of the last time the feed was fetched
      Rails.logger.debug "Updating time of last update for feed #{feed.id} - #{feed.title}"
      feed.reload.update! last_fetched: Time.zone.now

      if entries_after > entries_before
        # If new entries have been fetched, decrement the fetch interval
        ScheduleManager.decrement_update_interval feed
      else
        # If no new entries have been fetched, increment the fetch interval
        ScheduleManager.increment_update_interval feed
      end

      # Update unread entries count for all subscribed users.
      feed.users.find_each do |user|
        SubscriptionsManager.recalculate_unread_count feed, user
      end
    end
  end
end
