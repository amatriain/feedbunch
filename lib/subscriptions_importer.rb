require 'zip/zip'
require 'zip/zipfilesystem'

##
# This class manages import of subscription data from Google Reader into Feedbunch

class SubscriptionsImporter

  ##
  # This method extracts subscriptions data from an OPML file (probably exported from Google Reader), and
  # saves them in a (unzipped) OPML file in the filesystem. Afterwards it enqueues a background job
  # to import those subscriptions in the user's account.
  #
  # Receives as arguments the file uploaded by the user and user that requested the import.
  #
  # Optionally the file can be a zip archive; this is the format one gets when exporting from Google.

  def self.import_subscriptions(file, user)
    Rails.logger.info "User #{user.id} - #{user.email} requested import of a data file"
    data_import = user.create_data_import

    subscription_data = self.read_data_file file
  rescue => e
    Rails.logger.error "Error trying to read OPML data from file uploaded by user #{user.id} - #{user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    data_import.status = DataImport::ERROR
    data_import.save
    raise e
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
      zip_file = Zip::ZipFile.open file
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
    rescue Zip::ZipError => e
      # file is not a zip, read it normally
      Rails.logger.info 'Uploaded file is not a zip archive, it is probably an uncompressed OPML file'
      open_file = File.read file
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
        break
      end
    end

    return file_contents
  end
end