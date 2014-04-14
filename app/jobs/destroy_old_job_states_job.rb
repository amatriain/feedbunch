##
# Destroy instances of RefreshFeedJobState and SubscribeJobState older than 24 hours.
#
# After 24 hours, probably the user is no longer interested in the state of those jobs.

class DestroyOldJobStatesJob
  @queue = :update_feeds

  ##
  # Destroy instances of RefreshFeedJobState and SubscribeJobState older than 24 hours.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform
    time_old = Time.zone.now - Feedbunch::Application.config.destroy_job_states_after
    Rails.logger.info "Destroying job states created before #{time_old}"

    old_refresh_feed_jobs = RefreshFeedJobState.where 'created_at < ?', time_old
    Rails.logger.info "Destroying #{old_refresh_feed_jobs.count} old instances of RefreshFeedJobState"
    old_refresh_feed_jobs.destroy_all

    old_subscribe_jobs = SubscribeJobState.where 'created_at < ?', time_old
    Rails.logger.info "Destroying #{old_subscribe_jobs.count} old instances of SubscribeJobState"
    old_subscribe_jobs.destroy_all
  end
end