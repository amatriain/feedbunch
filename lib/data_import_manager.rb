require 'zip'
require 'zip/filesystem'

##
# This class manages import of subscription data from Google Reader into Feedbunch

class DataImportManager

  ##
  # This method extracts subscriptions data from an OPML file and
  # saves them in a (unzipped) OPML file in the filesystem. Afterwards it enqueues a background job
  # to import those subscriptions in the user's account.
  #
  # Receives as arguments the file uploaded by the user and user that requested the import.
  #
  # Optionally the file can be a zip archive; this is the format one gets when exporting from Google.
  #
  # If any error is raised during importing, this method raises an ImportDataError, to ensure that the user is
  # always redirected to the start page, instead of being left at a blank HTTP 500 page.

  def self.import(file, user)
    Rails.logger.info "User #{user.id} - #{user.email} requested import of a data file"
    data_import = user.create_data_import state: DataImport::RUNNING

    subscription_data = self.read_data_file file

    filename = "#{Time.now.to_i}.opml"
    Feedbunch::Application.config.uploads_manager.save filename, subscription_data

    Rails.logger.info "Enqueuing Import Subscriptions Job for user #{user.id} - #{user.email}, OPML file #{filename}"
    Resque.enqueue ImportSubscriptionsJob, filename, user.id
  rescue => e
    Rails.logger.error "Error trying to read OPML data from file uploaded by user #{user.id} - #{user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    data_import.state = DataImport::ERROR
    data_import.save
    raise ImportDataError.new
  end

  private

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
  # If no matching file is found inside the zip, an ImportDataError will be raised.

  def self.read_data_file(file)
    begin
      zip_file = Zip::File.open file
      file_contents = self.search_zip zip_file, /subscriptions.xml\z/
      file_contents = self.search_zip zip_file, /.opml\z/ if file_contents.blank?
      file_contents = self.search_zip zip_file, /.OPML\z/ if file_contents.blank?
      file_contents = self.search_zip zip_file, /.xml\z/ if file_contents.blank?
      file_contents = self.search_zip zip_file, /.XML\z/ if file_contents.blank?
      zip_file.close

      if file_contents.blank?
        Rails.logger.warn 'Could not find OPML file in uploaded data file'
        raise ImportDataError.new
      end
    rescue Zip::Error => e
      # file is not a zip, read it normally
      Rails.logger.info 'Uploaded file is not a zip archive, it is probably an uncompressed OPML file'
      file_contents = File.read file
    end

    return file_contents
  end

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
end