require 'subscriptions_manager'

##
# This class has methods to refresh feeds.

class FeedRefreshManager

  ##
  # Refresh a feed; this enqueues a job to fetch the feed from its server.
  #
  # Receives as argument the feed to refresh and the user that requested the refresh, if any.
  #
  # If less time than the minimum update interval has passed since the last time the feed was updated,
  # nothing is done.
  #
  # Returns nil.

  def self.refresh(feed, user)
    # If feed has never fetched, refresh it.
    if feed.last_fetched.blank?
      refresh_feed = true
    else
      # If more than the minimum update interval has passed since last update, refresh the feed.
      min_interval = Feedbunch::Application.config.min_update_interval
      if Time.zone.now > feed.last_fetched + min_interval
        refresh_feed = true
      # If less than the minimum update interval has passed, do not update feed
      else
        refresh_feed = false
      end
    end

    if refresh_feed
      Rails.logger.info "User #{user.id} - #{user.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
      job_state = user.refresh_feed_job_states.create feed_id: feed.id

      Rails.logger.info "Enqueuing refresh_feed_job_state #{job_state.id} for user #{user.id} - #{user.email}"
      Resque.enqueue RefreshFeedJob, job_state.id, feed.id, user.id
    else
      Rails.logger.info "User #{user.id} - #{user.email} is requesting to refresh feed #{feed.id} - #{feed.fetch_url} before minimum update interval has passed, ignoring request"
      job_state = user.refresh_feed_job_states.create feed_id: feed.id, state: RefreshFeedJobState::SUCCESS
    end

    return nil
  end
end