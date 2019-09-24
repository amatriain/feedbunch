# frozen_string_literal: true

require 'zip'
require 'zip/filesystem'
require 'nokogiri'

##
# This class manages import of subscription data from another feed aggregator into Feedbunch

class OPMLImporter

  # Class constant for the directory in which OPML export files will be saved.
  FOLDER = 'opml_imports'

  ##
  # This method extracts subscriptions data from an OPML file and
  # saves them in a (unzipped) OPML file in the filesystem. Afterwards it enqueues a background job
  # to import those subscriptions in the user's account.
  #
  # Receives as arguments the file uploaded by the user and user that requested the import.
  #
  # Optionally the file can be a zip archive; this is the format one gets when exporting from Google.
  #
  # If any error is raised during importing, this method raises an OpmlImportError, to ensure that the user is
  # always redirected to the start page, instead of being left at a blank HTTP 500 page.

  def self.enqueue_import_job(file, user)
    Rails.logger.info "User #{user.id} - #{user.email} requested import of a data file"
    # Destroy the current import job state for the user. This in turn triggers a deletion of any associated import failure data.
    user.opml_import_job_state&.destroy
    user.create_opml_import_job_state state: OpmlImportJobState::RUNNING

    subscription_data = read_data_file file
    filename = "feedbunch_import_#{Time.zone.now.to_i}.opml"
    Feedbunch::Application.config.uploads_manager.save user.id, FOLDER, filename, subscription_data

    Rails.logger.info "Enqueuing Import Subscriptions Job for user #{user.id} - #{user.email}, OPML file #{filename}"
    ImportOpmlWorker.perform_async filename, user.id
    return nil
  rescue => e
    Rails.logger.error "Error trying to read OPML data from file uploaded by user #{user.id} - #{user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    user.opml_import_job_state&.destroy
    user.create_opml_import_job_state state: OpmlImportJobState::ERROR
    raise OpmlImportError.new
  end

  ##
  # Process an OPML file with subscriptions for a user, and then delete it.
  #
  # Receives as arguments:
  # - the name of the file, including path from Rails.root (e.g. 'uploads/1371321122.opml')
  # - the user who is importing the file
  #
  # The file is retrieved using the currently configured uploads_manager (from the filesystem or from Amazon S3).

  def self.process_opml(filename, user)
    # Open file and check if it actually exists
    xml_contents = Feedbunch::Application.config.uploads_manager.read user.id, FOLDER, filename
    if xml_contents == nil
      Rails.logger.error "Trying to import for user #{user.id} from non-existing OPML file: #{filename}"
      raise OpmlImportError.new
    end

    # Parse OPML file (it's actually XML)
    begin
      docXml = Nokogiri::XML(xml_contents) {|config| config.strict}
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.error "Trying to parse malformed XML file #{filename}"
      raise e
    end

    # Count total number of feeds
    total_feeds = count_total_feeds docXml
    # Check that the file was actually an OPML file with feeds
    if total_feeds == 0
      Rails.logger.error "Trying to import for user #{user.id} from OPML file: #{filename} but file contains no feeds"
      raise OpmlImportError.new
    end
    # Update total number of feeds, so user can see progress.
    user.opml_import_job_state.update total_feeds: total_feeds

    # Arrays that will be passed to ImportSubscriptionsWorker
    urls = []
    folder_ids = []

    # Process feeds that are not in a folder
    docXml.xpath('/opml/body/outline[@type="rss" and @xmlUrl]').each do |feed_node|
      folder_ids << nil
      urls << feed_node['xmlUrl']
    end

    # Process feeds in folders
    docXml.xpath('/opml/body/outline[not(@type="rss")]').each do |folder_node|
      # Ignore <outline> nodes which contain no feeds
      if folder_node.xpath('./outline[@type="rss" and @xmlUrl]').present?
        folder_title = folder_node['title'] || folder_node['text']
        folder = import_folder folder_title, user
        folder_node.xpath('./outline[@type="rss" and @xmlUrl]').each do |feed_node|
          folder_ids << folder.id
          urls << feed_node['xmlUrl']
        end
      end
    end

    # Enqueue set of workers with sidekiq-superworker to import each individual feed
    ImportSubscriptionsWorker.perform_async user.opml_import_job_state.id, urls, folder_ids

    return nil
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Read a data file and return its contents. Accepts as argument a file, which can be:
  # - an unzipped data file
  # - a zip archive containing a data file. In this case the data file inside the zip
  # will be read and returned.
  #
  # When searching inside a zip archive for a data file, searches will be performed
  # in this order:
  # - a subscriptions.xml file
  # - any file with .opml extension
  # - any file with .OPML extension
  # - any file with .xml extension
  # - any file with .XML extension
  #
  # The first matching file found will be read and returned. Files will be found even
  # if they are inside a folder (or several levels of folders).
  #
  # If no matching file is found inside the zip, an OpmlImportError will be raised.

  def self.read_data_file(file)
    begin
      zip_file = Zip::File.open file
      file_contents = search_zip zip_file, /subscriptions.xml\z/
      file_contents = search_zip zip_file, /.opml\z/ if file_contents.blank?
      file_contents = search_zip zip_file, /.OPML\z/ if file_contents.blank?
      file_contents = search_zip zip_file, /.xml\z/ if file_contents.blank?
      file_contents = search_zip zip_file, /.XML\z/ if file_contents.blank?
      zip_file.close

      if file_contents.blank?
        Rails.logger.warn 'Could not find OPML file in uploaded data file'
        raise OpmlImportError.new
      end
    rescue Zip::Error => e
      # file is not a zip, read it normally
      Rails.logger.info 'Uploaded file is not a zip archive, it is probably an uncompressed OPML file'
      file_contents = File.read file
    end

    return file_contents
  end
  private_class_method :read_data_file

  ##
  # Search among the files in a zip archive a file which name (including extension)
  # matches the pattern passed as argument.
  #
  # Receives as arguments the opened zip file and the search pattern.
  #
  # The search is case-sensitive
  #
  # Returns the contents of the first mathing file found, or nil if there were no matches.

  def self.search_zip(zip_file, pattern)
    file_contents = nil
    zip_file.each do |f|
      if f.name =~ pattern
        Rails.logger.debug "Found OPML file #{f.name} in uploaded zip archive"
        file_contents = zip_file.file.read f.name
        file_contents.force_encoding 'utf-8'
        break
      end
    end

    return file_contents
  end
  private_class_method :search_zip

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
  private_class_method :count_total_feeds

  ##
  # Import a folder, creating it if necessary. The folder will be owned by the passed user.
  # If the user already has a folder with the same title, no action will be taken.
  #
  # Receives as arguments the title of the folder and the user who requested the import.
  #
  # Returns the folder. It may be a newly created folder, if the user didn't have a folder with the same title,
  # or it may be an already existing folder if he did.

  def self.import_folder(title, user)
    folder = user.folders.find_by title: title

    if folder.blank?
      Rails.logger.info "User #{user.id} - #{user.email} imported new folder #{title}, creating it"
      folder = user.folders.create title: title
    else
      Rails.logger.info "User #{user.id} - #{user.email} imported already existing folder #{title}, reusing it"
    end

    return folder
  end
  private_class_method :import_folder
end