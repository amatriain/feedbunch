# frozen_string_literal: true

require 'subscriptions_manager'

##
# Background job for user-requested updates to a feed.
#
# This is a Sidekiq worker

class RefreshFeedWorker
  include Sidekiq::Worker

  sidekiq_options queue: :interactive

  ##
  # Fetch and update entries for a feed, as requested by a user.
  # Receives as argument the id of the refresh_feed_job_state associated with this refresh.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(refresh_feed_job_state_id, feed_id, user_id)
    # Check if refresh_feed_job_state actually exists
    job_state = nil
    if RefreshFeedJobState.exists? refresh_feed_job_state_id
      job_state = RefreshFeedJobState.find refresh_feed_job_state_id
      # Check that the refresh_job_state is in state "RUNNING"
      if job_state.state != RefreshFeedJobState::RUNNING
        Rails.logger.warn "Processing RefreshFeedWorker for refresh_feed_job_state #{job_state.id}, it should be in state RUNNING but it is in state #{job_state.state}. Aborting."
        return
      end
    else
      Rails.logger.warn "Processing RefreshFeedWorker for refresh_feed_job_state #{refresh_feed_job_state_id} but that state does not exist in the database. Updating feed but job state will not be updated."
    end

    # Check that user actually exists
    if !User.exists? user_id
      Rails.logger.warn "User #{user_id} requested refresh of feed #{feed_id}, but the user does not exist in the database. Aborting"
      job_state.destroy if job_state.present?
      return
    end
    user = User.find user_id

    # Check that user is subscribed to the feed
    if !user.feeds.exists? feed_id
      Rails.logger.warn "User #{user.id} requested refresh of feed #{feed_id}, but the user is not subscribed to the feed. Aborting."
      job_state.destroy if job_state.present?
      return
    end

    # Check that feed actually exists
    if !Feed.exists? feed_id
      Rails.logger.warn "Feed #{feed_id} scheduled to be updated, but it does not exist in the database. Aborting."
      job_state.destroy if job_state.present?
      return
    end
    feed = Feed.find feed_id

    # Fetch feed
    Rails.logger.debug "Refreshing feed #{feed.id} - #{feed.title}"
    FeedClient.fetch feed

    Rails.logger.debug "Successfully finished refresh_feed_job_state #{refresh_feed_job_state_id} for feed #{feed&.id}, user #{user&.id}"
    job_state.update state: RefreshFeedJobState::SUCCESS if job_state.present?

    # If the update didn't fail, mark the feed as "not currently failing" and "available"
    feed.update failing_since: nil if !feed.failing_since.nil?
    feed.update available: true if !feed.available

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
    Rails.logger.warn "Error running refresh_feed_job_state #{refresh_feed_job_state_id} for feed #{feed&.id}, user #{user&.id}: #{e.message}"
    job_state.update state: RefreshFeedJobState::ERROR if job_state.present?
  ensure
    if feed.present? && Feed.exists?(feed&.id)
      # Update timestamp of the last time the feed was fetched
      Rails.logger.debug "Updating time of last update for feed #{feed.id} - #{feed.title}"
      feed.update! last_fetched: Time.zone.now

      # Update unread entries count for all subscribed users.
      feed.users.find_each do |user|
        SubscriptionsManager.recalculate_unread_count feed, user
      end
    end
  end
end