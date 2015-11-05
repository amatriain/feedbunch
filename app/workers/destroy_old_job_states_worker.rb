##
# Destroy instances of RefreshFeedJobState and SubscribeJobState older than 24 hours.
# After 24 hours, probably the user is no longer interested in the state of those jobs.
#
# This is a Sidekiq worker


class DestroyOldJobStatesWorker
  include Sidekiq::Worker

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

  ##
  # Destroy instances of RefreshFeedJobState and SubscribeJobState older than 24 hours.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    time_old = Time.zone.now - Feedbunch::Application.config.destroy_job_states_after
    Rails.logger.info "Destroying job states created before #{time_old}"

    old_refresh_feed_jobs = RefreshFeedJobState.where 'created_at < ?', time_old
    old_refresh_feed_jobs_count = old_refresh_feed_jobs.count
    Rails.logger.info "Destroying #{old_refresh_feed_jobs_count} old instances of RefreshFeedJobState"
    old_refresh_feed_jobs.destroy_all if old_refresh_feed_jobs_count > 0

    old_subscribe_jobs = SubscribeJobState.where 'created_at < ?', time_old
    old_subscribe_jobs_count = old_subscribe_jobs.count
    Rails.logger.info "Destroying #{old_subscribe_jobs_count} old instances of SubscribeJobState"
    old_subscribe_jobs.destroy_all if old_subscribe_jobs_count > 0
  end
end