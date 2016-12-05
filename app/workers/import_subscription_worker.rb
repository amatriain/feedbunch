##
# Background job to import a single feed subscription for a user.
#
# This is a Sidekiq worker.
#
# This worker is not enqueued directly, but rather is part of a batch set of workers enqueued by the
# sidekiq-superworker gem. It is always part of a global OPML import process.

class ImportSubscriptionWorker
  include Sidekiq::Worker

  sidekiq_options queue: :import_subscriptions

  ##
  # Import a single feed subscription for a user. Optionally the feed can be put into a folder.
  #
  # Receives as arguments:
  # - ID of the OpmlImportJobState instance. This object contains a reference to the user who is importing subscriptions,
  # so it's not necessary to pass the user ID as argument
  # - URL of the feed
  # - Optionally ID of the folder to put the feed into. Defaults to nil (feed won't be in a folder)
  #
  # When the worker finishes, it increments by 1 the current number of processed feeds in the global OPML import job state.
  # This enables the user to the import progress.
  #
  # This method is intended to be invoked from Sidekiq-superworker, which means it is performed in the background.

  def perform(opml_import_job_state_id, url, folder_id=nil)
    # Check if the opml import state actually exists
    if !OpmlImportJobState.exists? opml_import_job_state_id
      Rails.logger.error "Trying to perform ImportSubscriptionWorker as part of non-existing job state #{opml_import_job_state_id}. Aborting"
      return
    end
    opml_import_job_state = OpmlImportJobState.find opml_import_job_state_id
    user = opml_import_job_state.user

    # Check that opml_import_job_state has state RUNNING
    if opml_import_job_state.state != OpmlImportJobState::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} trying to perform ImportSubscriptionWorker as part of opml import with state #{opml_import_job_state.state} instead of RUNNING. Aborting"
      return
    end

    feed = import_feed user, url

    if folder_id.present? && feed.present?
      move_feed_to_folder user, feed, folder_id
    end
  ensure
    # Only update total processed feeds count if job is in state RUNNING
    if OpmlImportJobState.exists? opml_import_job_state_id
      opml_import_job_state.reload
      if opml_import_job_state&.state == OpmlImportJobState::RUNNING
        Rails.logger.info "Incrementing processed feeds in OPML import for user #{user&.id} - #{user&.email} by 1"
        processed_feeds = opml_import_job_state.reload.processed_feeds
        # Increment the count of processed feeds up to the total number of feeds
        opml_import_job_state.update processed_feeds: processed_feeds+1 if processed_feeds < opml_import_job_state.total_feeds
      else
        Rails.logger.warn "OPML import job state #{opml_import_job_state_id} has state #{opml_import_job_state&.state} instead of RUNNING. Total number of processed feeds will not be incremented"
        return
      end
    else
      Rails.logger.warn "OPML import job state #{opml_import_job_state_id} was destroyed during import of feed #{url}. Aborting"
      return
    end
  end

  private

  ##
  # Once the user is subscribed to the feed, move it to the passed folder.
  #
  # Receives as arguments:
  # - user that is performing the import
  # - feed that was just subscribed
  # - ID of the folder to move it to
  #
  # If the folder does not exist or is owned by a different user, nothing is done.

  def move_feed_to_folder(user, feed, folder_id)
    # Check if the passed folder exists
    if !Folder.exists? folder_id
      Rails.logger.warn "User #{user.id} - #{user.email} tried to put feed in non-existing folder #{folder_id} as part of opml import. Ignoring"
      return
    end
    folder = Folder.find folder_id

    # Check if the folder is owned by the user doing the import
    if folder.user != user
      Rails.logger.warn "User #{user.id} - #{user.email} tried to put feed in folder #{folder_id} owned by another user as part of opml import. Ignoring"
      return
    end

    user.move_feed_to_folder feed, folder: folder
  end

  ##
  # Import a feed, subscribing the user to it.
  #
  # Receives as arguments:
  # - the user performing the import
  # - url of the feed
  #
  # Returns the subscribe feed if successful, nil otherwise.

  def import_feed(user, url)
    Rails.logger.info "As part of OPML import, subscribing user #{user.id} - #{user.email} to feed #{url}"
    feed = user.subscribe url
    return feed
  rescue AlreadySubscribedError => e
    Rails.logger.error "During OPML import for user #{user&.id} - #{user&.email} found feed URL #{url} in OPML, but user is already subscribed to that feed. Ignoring it."
    Rails.logger.error e.message
    return user.feeds.find_by_fetch_url url
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
    FeedFetchError,
    OpmlImportError => e

    # all these errors mean the feed cannot be subscribed, but the job itself has not failed. Do not re-raise the error
    Rails.logger.warn "Controlled error during OPML import subscribing user #{user&.id} - #{user&.email} to feed URL #{url}: #{e.message}"
    add_failure user, url
    return nil
  rescue BlacklistedUrlError => e
    # If the url is in the blacklist, do not add subscription.
    Rails.logger.error "User #{user&.id} - #{user&.email} attempted to import subscription to blacklisted feed URL #{url}, ignoring it"
    add_failure user, url
    return nil
  rescue => e
    # an uncontrolled error has happened. Log the full backtrace but do not re-raise, so that the batch continues with next imported feed
    Rails.logger.error "Uncontrolled error during OPML import subscribing user #{user&.id} - #{user&.email} to feed URL #{url}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    add_failure user, url
    return nil
  end

  ##
  # Add a url to the list of failures for this OPML import.
  # Receives as argument the user doing the import and the failed url.

  def add_failure(user, url)
    failure = OpmlImportFailure.new url: url
    user.opml_import_job_state.opml_import_failures << failure
  end

end