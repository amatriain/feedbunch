require 'opml_import_notifier'

##
# Background job to send a notification email to the user when an opml import finishes.
#
# This is a Sidekiq worker
#
# This worker is not enqueued directly, but rather the sidekiq-superworker gem enqueues it after the batch
# of ImportSubscriptionWorker instances has finished. It is always part of a global OPML import process.

class NotifyImportFinishedWorker
  include Sidekiq::Worker

  sidekiq_options queue: :import_subscriptions

  ##
  # Send a notification email to the user when the opml import finishes.
  #
  # Receives as arguments:
  # - ID of the OpmlImportJobState instance. This object contains a reference to the user who is importing subscriptions,
  # so it's not necessary to pass the user ID as argument
  #
  # The import job must be in state RUNNING, otherwise nothing is done. If this worker finishes successfully the job
  # state is set to SUCCESS, if an error is raised it is set to ERROR.
  #
  # The notification email is different depending on whether the import finishes successfully or with an error. In case
  # of success, any feeds which could not be imported are detailed in the email.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(opml_import_job_state_id)
    # Check if the opml import state actually exists
    if !OpmlImportJobState.exists? opml_import_job_state_id
      Rails.logger.error "Trying to perform NotifyImportFinishedWorker as part of non-existing job state #{opml_import_job_state_id}. Aborting"
      return
    end
    opml_import_job_state = OpmlImportJobState.find opml_import_job_state_id
    user = opml_import_job_state.user

    # Check that opml_import_job_state has state RUNNING
    if opml_import_job_state.state != OpmlImportJobState::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} trying to perform NotifyImportFinishedWorker as part of opml import with state #{opml_import_job_state.state} instead of RUNNING. Aborting"
      return
    end

    OPMLImportNotifier.notify_success user
  rescue => e
    OPMLImportNotifier.notify_error user, e
  end

end