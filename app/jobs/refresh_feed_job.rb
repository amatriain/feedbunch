##
# Background job for user-requested updates to a feed.
#
# Its perform method will be invoked from a Resque worker.

class RefreshFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for a feed, as requested by a user.
  # Receives as argument the id of the refresh_feed_job_status associated with this refresh.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(refresh_feed_job_status_id)
    # Check that refresh_feed_job_status actually exists
    if !RefreshFeedJobStatus.exists? refresh_feed_job_status_id
      Rails.logger.warn "Processing RefreshFeedJob for refresh_feed_job_status #{refresh_feed_job_status_id} but that status does not exist in the database. Aborting"
      return
    end
    job_status = RefreshFeedJobStatus.find refresh_feed_job_status_id

    # Check that the refresh_job_status is in state "RUNNING"
    if job_status.status != RefreshFeedJobStatus::RUNNING
      Rails.logger.warn "Processing RefreshFeedJob for refresh_feed_job_status #{job_status.id}, it should be in state RUNNING but it is in status #{job_status.status}. Aborting."
      return
    end

    # Check that user actually exists
    if !User.exists? job_status.user_id
      Rails.logger.warn "User #{job_status.user_id} requested refresh of feed #{job_status.feed_id}, but the user does not exist in the database. Aborting"
      job_status.destroy
      return
    end
    user = User.find job_status.user_id

    # Check that user is subscribed to the feed
    if !user.feeds.exists? job_status.feed_id
      Rails.logger.warn "User #{user.id} requested refresh of feed #{job_status.feed_id}, but the user is not subscribed to the feed. Aborting."
      job_status.destroy
      return
    end

    # Check that feed actually exists
    if !Feed.exists? job_status.feed_id
      Rails.logger.warn "Feed #{job_status.feed_id} scheduled to be updated, but it does not exist in the database. Aborting."
      job_status.destroy
      return
    end
    feed = Feed.find job_status.feed_id

    # Fetch feed
    Rails.logger.debug "Refreshing feed #{feed.id} - #{feed.title}"
    FeedClient.fetch feed

    Rails.logger.debug "Successfully finished refresh_feed_job_status #{refresh_feed_job_status_id} for feed #{feed.try :id}, user #{user.try :id}"
    job_status.update status: RefreshFeedJobStatus::SUCCESS

    # If the update didn't fail, mark the feed as "not currently failing" and "available"
    feed.update failing_since: nil if !feed.failing_since.nil?
    feed.update available: true if !feed.available

  rescue RestClient::Exception, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, EmptyResponseError, FeedAutodiscoveryError, FeedFetchError, FeedParseError => e
    # all these errors mean the feed cannot be updated, but the job itself has not failed. Do not re-raise the error
    Rails.logger.error "Error running refresh_feed_job_status #{refresh_feed_job_status_id} for feed #{feed.try :id}, user #{user.try :id}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    if job_status.present?
      job_status.update status: RefreshFeedJobStatus::ERROR
    end
  ensure
    if feed.present?
      # Update timestamp of the last time the feed was fetched
      Rails.logger.debug "Updating time of last update for feed #{feed.id} - #{feed.title}"
      feed.update! last_fetched: Time.zone.now

      # Update unread entries count for all subscribed users.
      feed.users.each do |user|
        SubscriptionsManager.recalculate_unread_count feed, user
      end
    end
  end
end