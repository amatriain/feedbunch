require 'nokogiri'

##
# Background job to import an OPML data file with subscriptions data for a user.
# It also fetches any new feeds created (existing feeds are assumed
# to have been updated in the last hour and so don't need an update right now).
#
# Its perform method will be invoked from a Resque worker.

class ImportSubscriptionsJob
  @queue = :update_feeds

  ##
  # Import an OPML file with subscriptions for a user, and then deletes it.
  #
  # Receives as arguments:
  # - the name of the file, including path from Rails.root (e.g. 'uploads/1371321122.opml')
  # - the id of the user who is importing the file
  #
  # The file is retrieved using the currently configured uploads_manager (from the filesystem or from Amazon S3).
  #
  # After finishing the job the file will be deleted no matter what.
  #
  # The data_import of the user is updated (with the process status, total number of feeds and
  # current number of processed feeds) so that the user can see the import progress.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(filename, user_id)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to import OPML file #{filename} for non-existing user @#{user_id}"
      return
    end
    user = User.find user_id

    # Check that user has a data_import with status RUNNING
    if user.data_import.try(:status) != DataImport::RUNNING
      Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with status RUNNING, aborting OPML import"
      return
    end

    # Open file and check if it actually exists
    xml_contents = Feedbunch::Application.config.uploads_manager.read filename
    if xml_contents == nil
      Rails.logger.error "Trying to import for user #{user_id} from non-existing OPML file: #{filename}"
      self.import_status_error user
      return
    end

    # Parse OPML file (it's actually XML)
    begin
      docXml = Nokogiri::XML(xml_contents) {|config| config.strict}
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.error "Trying to parse malformed XML file #{filename}"
      self.import_status_error user
      return
    end

    # Count total number of feeds
    total_feeds = self.count_total_feeds docXml
    # Check that the file was actually an OPML file with feeds
    if total_feeds == 0
      self.import_status_error user
      return
    end
    # Update total number of feeds, so user can see progress.
    user.data_import.total_feeds = total_feeds
    user.data_import.save

    # Process feeds that are not in a folder
    docXml.xpath('/opml/body/outline[@type="rss" and @xmlUrl]').each do |feed_node|
      self.import_feed feed_node['xmlUrl'], user
    end

    # Process feeds in folders
    docXml.xpath('/opml/body/outline[not(@type="rss")]').each do |folder_node|
      folder = self.import_folder folder_node['title'], user
      folder_node.xpath('./outline[@type="rss" and @xmlUrl]').each do |feed_node|
        self.import_feed feed_node['xmlUrl'], user, folder
      end
    end

    # Once finished, mark import status as SUCCESS.
    self.import_status_success user
  rescue => e
    # If an exception is raised, set the import process status to ERROR
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    self.import_status_error user
    # Re-raise the exception so that Resque takes care of it
    raise e
  ensure
    Feedbunch::Application.config.uploads_manager.delete filename
  end

  private

  ##
  # Count the number of feeds in an OPML file.
  #
  # Receives as argument an OPML document parsed by Nokogiri.
  #
  # Returns the number of feeds in the document.

  def self.count_total_feeds(docXml)
    feeds_not_in_folders = docXml.xpath 'count(/opml/body/outline[@type="rss" and @xmlUrl])'
    feeds_in_folders = docXml.xpath 'count(/opml/body/outline[not(@type="rss")]/outline[@type="rss" and @xmlUrl])'
    return feeds_not_in_folders + feeds_in_folders
  end

  ##
  # Sets the data_import status for the user as ERROR.
  # Creates a new data_import if the user doesn't already have one.
  #
  # Receives as argument the user whose import process has failed.

  def self.import_status_error(user)
    user.create_data_import if user.data_import.blank?
    user.data_import.status = DataImport::ERROR
    user.data_import.save
    Rails.logger.info "Sending data import error email to user #{user.id} - #{user.email}"
    DataImportMailer.import_finished_error_email(user).deliver
  end

  ##
  # Sets the data_import status for the user as SUCCESS.
  #
  # Receives as argument the user whose import process has finished successfully.

  def self.import_status_success(user)
    user.data_import.status = DataImport::SUCCESS
    user.data_import.save
    Rails.logger.info "Sending data import success email to user #{user.id} - #{user.email}"
    DataImportMailer.import_finished_success_email(user).deliver
  end

  ##
  # Import a feed, subscribing the user to it.
  #
  # Receives as arguments:
  # - the fetch_url of the feed
  # - the user who requested the import (and who will be subscribed to the feed)
  # - optionally, the folder in which the feed will be (defaults to none)
  #
  # If the feed already exists in the database, the user is subscribed to it.

  def self.import_feed(fetch_url, user, folder=nil)
    begin
      feed = user.subscribe fetch_url
      if folder.present?
        Rails.logger.info "As part of OPML import, moving feed #{feed.id} - #{feed.title} to folder #{folder.title} owned by user #{user.id} - #{user.email}"
        folder.feeds << feed
      end
    rescue
      Rails.logger.error "Data import error: Error trying to subscribe user #{user.id} - #{user.email} to feed at #{fetch_url} from OPML file. Skipping to next feed"
      return
    ensure
      user.data_import.processed_feeds += 1
      user.data_import.save
    end
  end

  ##
  # Import a folder, creating it if necessary. The folder will be owned by the passed user.
  # If the user already has a folder with the same title, no action will be taken.
  #
  # Receives as arguments the title of the folder and the user who requested the import.
  #
  # Returns the folder. It may be a newly created folder, if the user didn't have a folder with the same title,
  # or it may be an already existing folder if he did.

  def self.import_folder(title, user)
    folder = user.folders.where(title: title).first

    if folder.blank?
      Rails.logger.info "User #{user.id} - #{user.email} imported new folder #{title}, creating it"
      folder = user.folders.create title: title
    else
      Rails.logger.info "User #{user.id} - #{user.email} imported already existing folder #{title}, reusing it"
    end

    return folder
  end
end