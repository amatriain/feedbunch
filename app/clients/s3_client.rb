##
# Class to manage uploading and deleting files from Amazon S3.
# Bucket name is feedbunch-#{Rails.env}, i.e. feedbunch-production for the production environment and
# feedbunch-staging for the staging environment.
# Files are uploaded and deleted from the "uploads" folder in the bucket.

require 'uri'

class S3Client

  ##
  # Save a file in Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as arguments the desired filename, the folder (under the bucket) in which the file will be
  # saved and the contents of the file.
  # File is saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.save(folder, filename, content)
    key = self.key folder, filename
    Rails.logger.info "Uploading to S3 object with key #{key}"
    s3_object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects.create key, content
    Rails.logger.debug "Succesfully uploaded to S3 object with key #{key}"
    return nil
  end

  ##
  # Delete a file from Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as argument the filename to delete and the folder (under the bucket) in which the file is expected to be.
  # File is expected to be saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.delete(folder, filename)
    key = self.key folder, filename
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    if object.exists?
      Rails.logger.info "deleting S3 object with key #{key}"
      object.delete
    else
      Rails.logger.error "trying to delete non-existing S3 object with key #{key}"
    end
    return nil
  end

  ##
  # Read a file from Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as argument the filename to be read and the folder (under the bucket) in which it's expected to be.
  # Returns the file contents if it exists, or nil otherwise.

  def self.read(folder, filename)
    key = self.key folder, filename
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    if object.exists?
      Rails.logger.info "reading S3 object with key #{key}"
      object_contents = object.read
    else
      Rails.logger.error "trying to read non-existing S3 object with key #{key}"
    end

    return object_contents
  end

  ##
  # Returns a boolean: true if a file with the passed filename exists, false otherwise.
  # Receives as arguments the filename and the folder in which it's expected to be.

  def self.exists?(folder, filename)
    key = self.key folder, filename
    Rails.logger.info "checking if S3 object with key #{key} exists"
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    exists = object.exists?
    if exists
      Rails.logger.info "S3 object with key #{key} exists"
    else
      Rails.logger.info "S3 object with key #{key} does not exist"
    end
    return exists
  end

  private

  ##
  # Get a file's S3 key, which can be used with the AWS API to operate on the file.
  # Receives as argument the filename which S3 key is to be calculated, and the folder (inside the bucket) in which
  # the file is expected to be.
  # Returns the S3 key for the file.
  # Assumptions:
  # - the S3 bucket for the file is feedbunch-#{Rails.env} (e.g. feedbunch-production for the
  # production environment)

  def self.key(folder, filename)
    key = "#{folder}/#{filename}"
    return key
  end
end
