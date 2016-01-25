require 'uri'

##
# Class to manage uploading and deleting files from Amazon S3.
# Bucket name is feedbunch-#{Rails.env}, i.e. feedbunch-production for the production environment and
# feedbunch-staging for the staging environment.
# Files are uploaded and deleted from the "uploads" folder in the bucket.

class S3Client

  ##
  # Save a file in Amazon S3. Amazon API keys must be present in an aws-sdk.rb file.
  # Accepts as arguments:
  # - the id of the user who is saving the file
  # - the folder (under the bucket) in which the file will be saved
  # - the filename
  # - the contents of the file.
  # File is saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.save(user_id, folder, filename, content)
    key = user_s3_key user_id, folder, filename
    Rails.logger.info "Uploading to S3 object with key #{key}"
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket Feedbunch::Application.config.s3_bucket
    bucket.put_object key: key, body: content
    Rails.logger.debug "Succesfully uploaded to S3 object with key #{key}"
    return nil
  end

  ##
  # Delete a file from Amazon S3. Amazon API keys must be present in an aws-sdk.rb file.
  # Accepts as arguments:
  # - the id of the user who is deleting the file
  # - the folder (under the bucket) in which the file is expected to be.
  # - the filename

  def self.delete(user_id, folder, filename)
    key = user_s3_key user_id, folder, filename
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket Feedbunch::Application.config.s3_bucket
    object = bucket.object key
    if object.exists?
      Rails.logger.info "deleting S3 object with key #{key}"
      object.delete
    else
      Rails.logger.error "trying to delete non-existing S3 object with key #{key}"
    end
    return nil
  end

  ##
  # Read a file from Amazon S3. Amazon API keys must be present in an aws-sdk.rb file.
  # Accepts as arguments:
  # - the id of the user who is reading the file
  # - the folder (under the bucket) in which the file is expected to be.
  # - the filename
  #
  # Returns the file contents if it exists, or nil otherwise.

  def self.read(user_id, folder, filename)
    key = user_s3_key user_id, folder, filename
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket Feedbunch::Application.config.s3_bucket
    object = bucket.object key
    if object.exists?
      Rails.logger.info "reading S3 object with key #{key}"
      object_contents = object.get.body.read
    else
      Rails.logger.error "trying to read non-existing S3 object with key #{key}"
    end

    return object_contents
  end

  ##
  # Returns a boolean: true if a file with the passed filename exists, false otherwise.
  # Receives as arguments:
  # - the id of the user who is checking the file existence
  # - the folder in which the file is expected to be found
  # - the filename

  def self.exists?(user_id, folder, filename)
    key = user_s3_key user_id, folder, filename
    Rails.logger.info "checking if S3 object with key #{key} exists"
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket Feedbunch::Application.config.s3_bucket
    object = bucket.object key
    exists = object.exists?
    if exists
      Rails.logger.info "S3 object with key #{key} exists"
    else
      Rails.logger.info "S3 object with key #{key} does not exist"
    end
    return exists
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Get a file's S3 key, which can be used with the AWS API to operate on the file.
  # Receives as arguments:
  # - the id of the user who "owns" the file
  # - the folder (inside the bucket) in which the file is expected to be.
  # - the filename
  #
  # Returns the S3 key for the file.
  # Assumes that the S3 bucket for the file is feedbunch-#{Rails.env} (e.g. feedbunch-production for the
  # production environment)

  def self.user_s3_key(user_id, folder, filename)
    key = "#{folder}/#{user_id}/#{filename}"
    return key
  end
  private_class_method :user_s3_key
end
