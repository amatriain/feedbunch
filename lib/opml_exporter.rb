require 'nokogiri'

##
# This class has methods related to exporting a user's subscriptions in OPML format.

class OPMLExporter

  ##
  # Enqueue a background job to export a user's subscriptions in OPML format.
  # Receives as argument the user who is doing the export.

  def self.enqueue_export_job(user)
    Rails.logger.info "Enqueuing export subscriptions job for user #{user.email} - #{user.name}"
    # Destroy the current export job state for the user. This in turn triggers a deletion of any old OPML file for the user.
    # This is not strictly necessary (just creating a new job state will delete the old one in the current ActiveRecord version),
    # but I think it's better if something this important is as explicit as possible.
    user.opml_export_job_state.destroy!
    user.create_opml_export_job_state state: OpmlExportJobState::RUNNING
    Resque.enqueue ExportSubscriptionsJob, user.id
    return nil
  rescue => e
    Rails.logger.error "Error trying to export subscriptions in OPML format for user #{user.id} - #{user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
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
          user.folders.each do |folder|
            xml.outline(title: folder.title, text: folder.title) {
              user.folder_feeds(folder, include_read: true).each do |feed|
                xml.outline type: 'rss', title: feed.title, text: feed.title, xmlUrl: feed.fetch_url, htmlUrl: feed.url
              end
            }
          end
        }
      }
    end
    opml = builder.to_xml

    filename = self.user_filename user
    # Save the OPML file in permanent storage for later retrieval.
    Feedbunch::Application.config.uploads_manager.save filename, opml

    # Update job state
    user.opml_export_job_state.update state: OpmlExportJobState::SUCCESS,
                                      filename: filename

    return opml
  end

  private

  ##
  # Return the filename that will be used for the OPML export created by a user.
  #
  # This filename is guaranteed to be different for each user, and it's easy to find the file for a given user because
  # the filename includes the user's email, which is guaranteed to be unique.
  #
  # The filename is always the same for a given user, because the app will not keep more than one OPML export for a given
  # user.

  def self.user_filename(user)
    filename = "feedbunch_#{user.email}.opml"
    return filename
  end

end