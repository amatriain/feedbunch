require 'zip/zip'
require 'zip/zipfilesystem'

##
# This class manages import of subscription data from Google Reader into Feedbunch

class SubscriptionsImporter

  ##
  # This method extracts subscriptions data from an OPML file (probably exported from Google Reader), and
  # imports those subscriptions to Feedbunch, so that the user that uploaded the file
  # gets subscribed to the feeds.
  #
  # Optionally the file can be zipped; this is the format one gets when exporting from Google.
  #
  # Folders are also imported, and feeds moved into folders as necessary.
  #
  # Imported feeds that were not in the database are fetched, to populate their current entries.

  def self.import_subscriptions(file, user)
    data_import = user.create_data_import

    subscription_data = self.read_data_file file
  rescue => e
    data_import.destroy
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
      raise ImportDataError.new if file_contents.blank?
    rescue Zip::ZipError => e
      # file is not a zip
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
        file_contents = zip_file.file.read f.name
        break
      end
    end

    return file_contents
  end
end