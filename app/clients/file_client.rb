##
# Class to manage saving and deleting files from the filesystem.
# Files are uploaded and deleted from the "uploads" folder under the Rails root.

class FileClient

  ##
  # Save a file in the filesystem.
  # Accepts as arguments the desired filename and the contents of the file.
  # File is saved in the "uploads" folder under the Rails root.

  def self.save(filename, content)
    filepath = self.filepath filename
    Rails.logger.info "Saving file #{filepath}"
    File.open(filepath, 'w'){|file| file.write content}
  end

  ##
  # Delete a file from the filesystem.
  # Accepts as argument the filename to delete.
  # File is expected to be saved in the "uploads" folder under the Rails root.

  def self.delete(filename)
    filepath = self.filepath filename
    Rails.logger.info "deleting file #{filepath}"
    File.delete filepath
  end

  ##
  # Read a file from the filesystem.
  # Accepts as argument the filename to be read. This file is expected to be saved in the "uploads"
  # folder under the Rails root.
  # Returns the file contents if it exists, nil otherwise.

  def self.read(filename)
    filepath = self.filepath filename
    Rails.logger.info "reading file #{filepath}"
    contents = File.read filepath if FileTest.exists? filepath
    return contents
  end

  ##
  # Returns a boolean: true if a file with the passed filename exists, false otherwise.
  # The file is searched in the "uploads" folder under the Rails root.

  def self.exists?(filename)
    filepath = self.filepath filename
    Rails.logger.info "searching for file #{filepath}"
    exists = FileTest.exists? filepath
    if exists
      Rails.logger.info "#{filepath} exists"
    else
      Rails.logger.info "#{filepath} does not exist"
    end
    return exists
  end

  private

  ##
  # Get a file's filepath, which can be used to operate on it in the filesystem.
  # Receives as argument the filename which path is to be calculated.
  # Returns the relative path (including filename) from the Rails root for the file.
  # Assumptions:
  # - the file is under the "uploads" folder in Rails root.

  def self.filepath(filename)
    filepath = File.join Rails.root, 'uploads', filename
    return filepath
  end
end
