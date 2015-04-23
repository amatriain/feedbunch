require 'nokogiri'

##
# This class has methods related to exporting a user's subscriptions in OPML format.

class OPMLExporter

  # Class constant for the directory in which OPML export files will be saved.
  FOLDER = 'opml_exports'

  # Class constant for the name with which the OPML export file will be downloaded and attached to the notification email.
  FILENAME= 'feedbunch_export.opml'

  ##
  # Enqueue a background job to export a user's subscriptions in OPML format.
  # Receives as argument the user who is doing the export.

  def self.enqueue_export_job(user)
    Rails.logger.info "Enqueuing export subscriptions job for user #{user.email} - #{user.name}"
    # Destroy the current export job state for the user. This in turn triggers a deletion of any old OPML file for the user.
    user.opml_export_job_state.try :destroy
    user.create_opml_export_job_state state: OpmlExportJobState::RUNNING

    ExportSubscriptionsWorker.perform_async user.id
    return nil
  rescue => e
    Rails.logger.error "Error trying to export subscriptions in OPML format for user #{user.id} - #{user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    user.opml_export_job_state.try :destroy
    user.create_opml_export_job_state state: OpmlExportJobState::ERROR
    raise OpmlExportError.new
  end

  ##
  # Export a user's subscriptions in OPML format
  #
  # Receives as arguments:
  # - user doing the export.
  #
  # If successful, saves a file with the OPML export in the currently configured upload manager (Amazon S3 in production).
  # It also updates the state attribute of the user's opml_export_job_state to "SUCCESS".
  #
  # Returns a string with the OPML.

  def self.export(user)
    # Compose the OPML file (actually XML)
    feeds_outside_folders = user.folder_feeds Folder::NO_FOLDER, include_read: true
    # Sort feeds by title, mainly for easier testing
    feeds_outside_folders.sort_by!{|a| a.title}
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.opml(version: '1.0') {
        xml.head {
          xml.title 'RSS subscriptions exported by Feedbunch (feedbunch.com)'
          xml.ownerName user.name
          xml.ownerEmail user.email
          xml.dateCreated Time.zone.now.rfc2822
        }
        xml.body {
          # feeds which are not in a folder
          feeds_outside_folders.each do |feed|
            xml.outline type: 'rss', title: feed.title, text: feed.title, xmlUrl: feed.fetch_url, htmlUrl: feed.url
          end
          # folders
          user.folders.order(:title).find_each do |folder|
            xml.outline(title: folder.title, text: folder.title) {
              user.folder_feeds(folder, include_read: true).order(:title).find_each do |feed|
                xml.outline type: 'rss', title: feed.title, text: feed.title, xmlUrl: feed.fetch_url, htmlUrl: feed.url
              end
            }
          end
        }
      }
    end
    opml = builder.to_xml
    return opml
  end

  ##
  # Return the contents of a user's previously exported OPML file.
  # Receives as argument the user who is retrieving the export file.
  # Returns the contents of the OPML export file.
  # If an export file doesn't exist for the user, an OpmlExportDoesNotExistError will be raised.

  def self.get_export(user)
    # User should have an OPML export filename saved in the db.
    # This will only happen if the opml_export_job_state has state "SUCCESS", but the OpmlExportJobState model
    # takes care of that.
    if user.opml_export_job_state.filename.blank?
      Rails.logger.error "User #{user.id} - #{user.email} tried to download his OPML export file, but he has none"
      raise OpmlExportDoesNotExistError.new
    end

    filename = user.opml_export_job_state.filename
    # Check that the file with the saved filename actually exists.
    if !Feedbunch::Application.config.uploads_manager.exists? user.id, OPMLExporter::FOLDER, filename
      Rails.logger.error "User #{user.id} - #{user.email} tried to download his OPML export file #{filename} but it doesn't exist"
      raise OpmlExportDoesNotExistError.new
    end

    opml_data = Feedbunch::Application.config.uploads_manager.read user.id, OPMLExporter::FOLDER, filename
    return opml_data
  end

end