##
# Background job to send a notification email to the user when an opml import finishes.
#
# This is a Sidekiq worker
#
# This worker is not enqueued directly, but rather the sidekiq-superworker gem enqueues it after the batch
# of ImportSubscriptionWorker instances has finished. It is always part of a global OPML import process.

class NotifyImportFinishedWorker
  include Sidekiq::Worker

  sidekiq_options queue: :update_feeds

  ##
  # Send a notification email to the user when the opml import finishes.
  #
  # Receives as arguments:
  # - ID of the OpmlImportJobState instance. This object contains a reference to the user who is importing subscriptions,
  # so it's not necessary to pass the user ID as argument
  #
  # The state of the opml import job is guaranteed to be either SUCCESS or ERROR when this job finishes.
  #
  # The notification email is different depending on whether the import finished successfully or with an error. In case
  # of success, any feeds which could not be imported are detailed in the email.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(opml_import_job_state_id)
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