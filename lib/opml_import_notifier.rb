##
# This class has methods related to sending emails to notify a user that an opml import process has finished

class OPMLImportNotifier

  ##
  # Send a success notification email to a user. Also set the import job state to SUCCESS.
  # Receives as argument the user to be notified.

  def self.notify_success(user)
    Rails.logger.info "OPML import for user #{user.id} - #{user.email} finished successfully. #{user.opml_import_job_state.total_feeds} feeds in OPML file, #{user.opml_import_job_state.processed_feeds} feeds imported"

    user.opml_import_job_state.update state: OpmlImportJobState::SUCCESS

    Rails.logger.info "Sending data import success email to user #{user.id} - #{user.email}"
    OpmlImportMailer.import_finished_success_email(user).deliver_now
  end

  ##
  # Send an error notification email to a user. Also set the import job state to ERROR.
  # Receives as argument:
  # - user to be notified
  # - optionally, raised error (if any)

  def self.notify_error(user, error=nil)
    # If an exception is raised, set the import process state to ERROR
    if user.present?
      user.create_opml_import_job_state if user.opml_import_job_state.blank?
      user.opml_import_job_state.update state: OpmlImportJobState::ERROR
      Rails.logger.info "Sending data import error email to user #{user.id} - #{user.email}"
      OpmlImportMailer.import_finished_error_email(user).deliver_now
    end

    Rails.logger.info "OPML import for user #{user&.id} - #{user&.email} finished with an error"
    if error.present?
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      # Re-raise the exception so that Sidekiq takes care of it,
      # unless it is a known controlled error (e.g. user uploaded a non-xml file).
      raise error unless error.is_a? Nokogiri::XML::SyntaxError
    end
  end

end