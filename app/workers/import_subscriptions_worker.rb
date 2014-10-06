##
# Background job to import an OPML data file with subscriptions data for a user.
# It enqueues jobs to subscribe the user to each individual feed.
#
# This is a Sidekiq worker

class ImportSubscriptionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :interactive

  ##
  # Import an OPML file with subscriptions for a user, and then deletes it.
  #
  # Receives as arguments:
  # - the name of the file, including path from Rails.root (e.g. 'uploads/1371321122.opml')
  # - the id of the user who is importing the file
  #
  # The opml_import_job_state of the user is updated (with the process state, total number of feeds and
  # current number of processed feeds) so that the user can see the import progress.
  #
  # After finishing the job the file will be deleted no matter what.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(filename, user_id)
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

  rescue => e
    # If an exception is raised, set the import process state to ERROR
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    import_state_error user
    # Re-raise the exception so that Resque takes care of it
    raise e
  ensure
    Feedbunch::Application.config.uploads_manager.delete user, OPMLImporter::FOLDER, filename
  end

  private

  ##
  # Sets the opml_import_job_state state for the user as ERROR.
  # Creates a new opml_import_job_state if the user doesn't already have one.
  #
  # Receives as argument the user whose import process has failed.

  def import_state_error(user)
    user.create_opml_import_job_state if user.opml_import_job_state.blank?
    user.opml_import_job_state.state = OpmlImportJobState::ERROR
    user.opml_import_job_state.save
    Rails.logger.info "Sending data import error email to user #{user.id} - #{user.email}"
    OpmlImportMailer.import_finished_error_email(user).deliver
  end

end