##
# Background job to subscribe a user to a feed.
#
# This is a Sidekiq worker

class SubscribeUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :interactive

  ##
  # Subscribe a user to a feed
  #
  # Receives as arguments:
  # - id of the user
  # - url of the feed
  # - id of the SubscribeJobState instance that reflects the state of the job
  #
  # The state field of the SubscribeJobState instance will be updated when
  # the job finishes, to reflect whether it finished successfully or with an error.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(user_id, feed_url, job_state_id)
    # Find the SubscribeJobState instance for this job, if it exists
    if SubscribeJobState.exists? job_state_id
      job_state = SubscribeJobState.find job_state_id
      # Check that the subscribe_job_state is in state "RUNNING"
      if job_state.state != SubscribeJobState::RUNNING
        Rails.logger.error "Processing SubscribeUserWorker for subscribe_job_state_id #{job_state_id}, it should be in state RUNNING but it is in state #{job_state.state}. Aborting."
        return
      end
    else
      Rails.logger.error "Processing SubscribeUserWorker for subscribe_job_state_id #{job_state_id}, but no job state with that ID exists. Aborting."
      return
    end

    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to add subscription to non-existing user @#{user_id}, aborting job"
      job_state.destroy if job_state.present?
      return
    end
    user = User.find user_id

    Rails.logger.info "Subscribing user #{user.id} - #{user.email} to feed #{feed_url}"
    feed = user.subscribe feed_url

    # Set job state to "SUCCESS" and save the id of the actually subscribed feed
    job_state.update state: SubscribeJobState::SUCCESS, feed_id: feed.id if job_state.present?
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
      AlreadySubscribedError,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError,
      OpmlImportError => e
    # all these errors mean the feed cannot be subscribed, but the job itself has not failed. Do not re-raise the error
    Rails.logger.warn "Controlled error subscribing user #{user&.id} - #{user&.email} to feed URL #{feed_url}: #{e.message}"
    job_state.update state: SubscribeJobState::ERROR if job_state.present?
  rescue => e
    Rails.logger.error "Uncontrolled error subscribing user #{user&.id} - #{user&.email} to feed URL #{feed_url}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    job_state.update state: SubscribeJobState::ERROR if job_state.present?
    # The job has failed. Re-raise the exception so that Sidekiq takes care of it
    raise e
  end

end
