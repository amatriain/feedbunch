##
# Class to manage saving and deleting files from the filesystem.
# Files are uploaded and deleted from the "uploads" folder under the Rails root.

class FileClient

  ##
  # Save a file in the filesystem.
  # Accepts as arguments the desired filename, the filesystem folder where it should be (relative to the Rails root)
  # and the contents of the file.

  def self.save(folder, filename, content)
    filepath = self.filepath folder, filename
    # Create folder if necessary
    FileUtils.mkdir_p File.dirname(filepath)
    Rails.logger.info "Saving file #{filepath}"
    File.open(filepath, 'w'){|file| file.write content}
    return nil
  end

  ##
  # Delete a file from the filesystem.
  # Accepts as argument the filename to delete and the folder where it's expected to be (relative to the Rails root).
  # File is expected to be saved in the "uploads" folder under the Rails root.

  def self.delete(folder, filename)
    filepath = self.filepath folder, filename
    if FileTest.exists? filepath
      Rails.logger.info "deleting file #{filepath}"
      File.delete filepath
    else
      Rails.logger.error "trying to delete non-existing file #{filepath}"
    end
    return nil
  end

  ##
  # Read a file from the filesystem.
  # Accepts as argument the filename to be read and the folder where the file should be (relative to the Rails root).
  # Returns the file contents if it exists, nil otherwise.

  def self.read(folder, filename)
    filepath = self.filepath folder, filename
    if FileTest.exists? filepath
      Rails.logger.info "reading file #{filepath}"
      contents = File.read filepath
    else
      Rails.logger.error "trying to read non-existing file #{filepath}"
    end

    return contents
  end

  ##
  # Returns a boolean: true if a file with the passed filename exists, false otherwise.
  # The file is searched in the passed folder (relative to the Rails root).

  def self.exists?(folder, filename)
    filepath = self.filepath folder, filename
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
  # Receives as argument the filename which path is to be calculated and the folder in which it's
  # expected to be (relative to the Rails root)..
  # Returns the relative path (including filename) from the Rails root for the file.

  def self.filepath(folder, filename)
    filepath = File.join Rails.root, folder, filename
    return filepath
  end
end
