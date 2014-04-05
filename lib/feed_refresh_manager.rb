require 'subscriptions_manager'

##
# This class has methods to refresh feeds.

class FeedRefreshManager

  ##
  # Refresh a feed; this enqueues a job to fetch the feed from its server.
  #
  # Receives as argument the feed to refresh and the user that requested the refresh, if any.
  #
  # Returns nil.

  def self.refresh(feed, user)
    Rails.logger.info "User #{user.id} - #{user.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    job_status = user.refresh_feed_job_statuses.create feed_id: feed.id

    Rails.logger.info "Enqueuing refresh_feed_job_status #{job_status.id} for user #{user.id} - #{user.email}"
    Resque.enqueue RefreshFeedJob, job_status.id, feed.id, user.id
    return nil
  end
end