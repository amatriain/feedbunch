require 'opml_import_notifier'
require 'opml_importer'

##
# Background job to import an OPML data file with subscriptions data for a user.
# After processing the OPML file it enqueues a superworker (using the sidekiq-superworker gem) to import each feed in
# the data file in batches of individual jobs.
#
# This is a Sidekiq worker

class ImportOpmlWorker
  include Sidekiq::Worker

  sidekiq_options queue: :import_subscriptions

  ##
  # Imports an OPML file with subscriptions for a user, and then deletes it.
  #
  # Receives as arguments:
  # - the name of the file, including path from Rails.root (e.g. 'uploads/1371321122.opml')
  # - the id of the user who is importing the file
  #
  # The opml_import_job_state of the user is updated with the total number of feeds so that the user can see the
  # import progress.
  #
  # After finishing the job the file will be deleted no matter what.
  #
  # Folders present in the file will be created if they don't already exist.
  #
  # After this job finishes an ImportSubscriptionsWorker superworker will be enqueued, passing the feeds and folders
  # present in the OPML as arguments. Thanks to sidekiq-superworker the actual work of importing each individual feed
  # and moving it to the corresponding folder will be delegated to lightweigth ImportSubscriptionWorker instances.
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
    if user.opml_import_job_state&.state != OpmlImportJobState::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with state RUNNING, aborting OPML import"
      return
    end

    OPMLImporter.process_opml filename, user
  rescue => e
    OPMLImportNotifier.notify_error user, e
  ensure
    Feedbunch::Application.config.uploads_manager.delete user_id, OPMLImporter::FOLDER, filename
  end

end