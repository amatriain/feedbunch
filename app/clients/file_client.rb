##
# Class to manage saving and deleting files from the filesystem.
# Files are uploaded and deleted from the "uploads" folder under the Rails root.

class FileClient

  ##
  # Save a file in the filesystem.
  # Accepts as arguments:
  # - the id of the user who is saving the file
  # - the folder under which the file will be saved (relative to Rails root)
  # - the filename
  # - the contents of the file.

  def self.save(user_id, folder, filename, content)
    filepath = user_file_path user_id, folder, filename
    # Create folder if necessary
    FileUtils.mkdir_p File.dirname(filepath)
    Rails.logger.info "Saving file #{filepath}"
    File.open(filepath, 'w'){|file| file.write content}
    return nil
  end

  ##
  # Delete a file from the filesystem.
  # Accepts as arguments:
  # - the id of the user who is deleting the file
  # - the folder under which should be the file (relative to Rails root)
  # - the filename to delete

  def self.delete(user_id, folder, filename)
    filepath = user_file_path user_id, folder, filename
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
  # Accepts as arguments:
  # - the id of the user who is reading the file
  # - the folder under which the file should be (relative to Rails root)
  # - the filename to be read
  #
  # Returns the file contents if it exists, nil otherwise.

  def self.read(user_id, folder, filename)
    filepath = user_file_path user_id, folder, filename
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
  # Accepts as arguments:
  # - the id of the user who owns the file, if it exists
  # - the folder in which to search
  # - the filename

  def self.exists?(user_id, folder, filename)
    filepath = user_file_path user_id, folder, filename
    Rails.logger.info "searching for file #{filepath}"
    exists = FileTest.exists? filepath
    if exists
      Rails.logger.info "#{filepath} exists"
    else
      Rails.logger.info "#{filepath} does not exist"
    end
    return exists
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Get a file's filepath, which can be used to operate on it in the filesystem.
  #
  # Receives as arguments:
  # - the id of the user who "owns" the file
  # - the folder under which the file is expected to be (relative to the Rails root)
  # - the filename
  #
  # It is assumed that files owned by a user will be in a subfolder named with the user's ID.
  #
  # Returns the relative path (including filename) from the Rails root for the file.

  def self.user_file_path(user_id, folder, filename)
    filepath = File.join Rails.root, folder, user_id.to_s, filename
    return filepath
  end
  private_class_method :user_file_path
end
