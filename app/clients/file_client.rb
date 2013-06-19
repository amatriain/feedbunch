##
# Class to manage saving and deleting files from the filesystem.
# Files are uploaded and deleted from the "uploads" folder under the Rails root.

class FileClient

  ##
  # Save a file in the filesystem.
  # Accepts as arguments the desired filename and the contents of the file.
  # File is saved in the "uploads" folder under the Rails root.

  def self.save(filename, content)
    Rails.logger.info "Saving file #{filename} in uploads folder"
    filepath = File.join Rails.root, 'uploads', filename
    File.open(filepath, 'w'){|file| file.write content}
  end

  ##
  # Delete a file from the filesystem.
  # Accepts as argument the filename to delete.
  # File is expected to be saved in the "uploads" folder under the Rails root.

  def self.delete(filename)
    Rails.logger.info "deleting file #{filename} from uploads folder"
    filepath = File.join Rails.root, 'uploads', filename
    File.delete filepath
  end

end
