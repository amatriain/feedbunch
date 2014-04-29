require 'opml_exporter'

##
# Background job to export an OPML data file with subscriptions data for a user.
#
# Its perform method will be invoked from a Resque worker.

class ExportSubscriptionsJob
  @queue = :subscriptions

  ##
  # Export an OPML file with subscriptions for a user. It will be saved in permanent storage (Amazon S3 or similar).
  # No more than one OPML file will be kept for each user.
  #
  # Receives as argument the id of the user who is exporting.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(user_id)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to export OPML file for non-existing user #{user_id}"
      return
    end
    user = User.find user_id

    # Check that user has a data_export with state RUNNING
    if user.opml_export_job_state.try(:state) != OpmlExportJobState::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} does not have a data export with state RUNNING, aborting OPML export"
      return
    end

    # Export and save the OPML file (actually XML)
    opml = OPMLExporter.export user

    # Send success notification email
    filename = 'feedbunch_export.opml'
    OpmlExportMailer.export_finished_success_email(user, filename, opml).deliver
  rescue => e
    # If an exception is raised, set the export process state to ERROR
    Rails.logger.error e.message
    Rails.logger.error e.backtrace

    # Send error notification email
    OpmlExportMailer.export_finished_error_email(user).deliver

    # Update job state
    user.opml_export_job_state.update state: OpmlExportJobState::ERROR if user.present?

    # Re-raise the exception so that Resque takes care of it
    raise e
  end
end