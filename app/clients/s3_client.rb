##
# Class to manage uploading and deleting files from Amazon S3.
# Bucket name is feedbunch-#{Rails.env}, i.e. feedbunch-production for the production environment and
# feedbunch-staging for the staging environment.
# Files are uploaded and deleted from the "uploads" folder in the bucket.

require 'uri'

class S3Client

  ##
  # Save a file in Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as arguments the desired filename and the contents of the file.
  # File is saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.save(filename, content)
    key = self.key filename
    Rails.logger.info "Uploading to S3 object with key #{key}"
    s3_object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects.create key, content
    Rails.logger.debug "Succesfully uploaded to S3 object with key #{key}"
  end

  ##
  # Delete a file from Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as argument the filename to delete.
  # File is expected to be saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.delete(filename)
    key = self.key filename
    Rails.logger.info "deleting S3 object with key #{key}"
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    object.delete
  end

  ##
  # Read a file from Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as argument the filename to be read. This file is expected to be saved in the "uploads"
  # folder in the feedbunch-#{Rails.env} bucket.
  # Returns the file contents if it exists, or nil otherwise.

  def self.read(filename)
    key = self.key filename
    Rails.logger.info "reading S3 object with key #{key}"
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    object_contents = object.read if object.exists?
    return object_contents
  end

  ##
  # Returns a boolean: true if a file with the passed filename exists, false otherwise.
  # The file is searched in the "uploads" folder under the Rails root.

  def self.exists?(filename)
    key = self.key filename
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
  # Receives as argument the filename which S3 key is to be calculated.
  # Returns the S3 key for the file.
  # Assumptions:
  # - the S3 bucket for the file is feedbunch-#{Rails.env} (e.g. feedbunch-production for the
  # production environment)
  # - the file is under the "uploads" folder in the bucket.

  def self.key(filename)
    key = "uploads/#{filename}"
    return key
  end
end
