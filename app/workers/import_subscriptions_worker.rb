##
# Background job to import a set of feed subscriptions for a user.
#
# This is a Sidekiq worker
#
# This worker acts as the superworker for a batch of ImportSubscriptionWorker instances, each of
# which imports a single subscription. This is achieved with the sidekiq-superworker gem.

class ImportSubscriptionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :update_feeds

  ##
  # Import a set of subscriptions for a user, by starting a batch of smaller workers with sidekiq-superworker.
  #
  # Receives as arguments:
  # - ID of the OpmlImportJobState instance. This object contains a reference to the user who is importing subscriptions,
  # so it's not necessary to pass the user ID as argument
  # - array of feed URLs
  # - array of folder IDs
  #
  # The length of both arrays (feed URLs and folder IDs) must be the same. Otherwise the passed folder_ids array will be
  # ignored, an array of the correct length filled with nil values will be used instead.
  #
  # Once imported each feed will be put into the folder identified by the corresponding folder ID; e.g. once the feed
  # with URL urls[i] has been subscribed, it will be put in the folder with ID folder_ids[i].
  #
  # The folder_ids array can contain nil values; they mean that the corresponding feed from the URLs array won't be
  # moved into any folder.
  #
  # All elements of the folder_ids array must be either nil or valid IDs of already existing folders owned by the user
  # who initiated the import. Any other folder IDs (e.g. an ID corresponding to a folder owned by another user) will
  # be ignored and a nil value will be used in its place.
  #
  # While this superworker is running, the individual ImportSubscriptiionWorker instances started in batch will
  # update the total number of processed feeds, so that the user can see the progress of the process.
  #
  # Once the superworker finishes, either successfully or with an error, a notification email will be sent to the user.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(opml_import_job_state_id, urls, folder_ids)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to import OPML file #{filename} for non-existing user #{user_id}"
      return
    end
    user = User.find user_id

    # Check that user has a opml_import_job_state with state RUNNING
    if user.opml_import_job_state.try(:state) != OpmlImportJobState::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with state RUNNING, aborting OPML import"
      return
    end

    OPMLImporter.import filename, user
    import_success user
  rescue => e
    import_error user, e
  ensure
    Feedbunch::Application.config.uploads_manager.delete user, OPMLImporter::FOLDER, filename
  end

  private

  ##
  # Operations performed when the import finishes successfully.
  # Sets the opml_import_job_state state for the user as SUCCESS
  # Sends a notification email to the user.
  #
  # Receives as argument:
  # - user whose import process has finished successfully

  def import_success(user)
    Rails.logger.info "OPML import for user #{user.id} - #{user.email} finished successfully. #{user.opml_import_job_state.total_feeds} feeds in OPML file, #{user.opml_import_job_state.processed_feeds} feeds imported"

    user.opml_import_job_state.update state: OpmlImportJobState::SUCCESS

    Rails.logger.info "Sending data import success email to user #{user.id} - #{user.email}"
    OpmlImportMailer.import_finished_success_email(user).deliver_now
  end

  ##
  # Operations performed when the import finishes with an error.
  # Sets the opml_import_job_state state for the user as ERROR.
  # Sends a notification email to the user.
  #
  # Receives as arguments:
  # - the user whose import process has failed
  # - the error raised, if any

  def import_error(user, error=nil)
    # If an exception is raised, set the import process state to ERROR
    Rails.logger.info "OPML import for user #{user.id} - #{user.email} finished with an error"
    if error.present?
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
    end

    user.create_opml_import_job_state if user.opml_import_job_state.blank?
    user.opml_import_job_state.update state: OpmlImportJobState::ERROR

    Rails.logger.info "Sending data import error email to user #{user.id} - #{user.email}"
    OpmlImportMailer.import_finished_error_email(user).deliver_now

    # Re-raise the exception so that Sidekiq takes care of it
    raise error
  end

end