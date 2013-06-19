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
    key = "uploads/#{filename}"
    Rails.logger.info "Uploading to S3 object with key #{key}"
    s3_object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects.create key, content
    Rails.logger.debug "Succesfully uploaded to S3 object with key #{key}"
  end

  ##
  # Delete a file from Amazon S3. Amazon API keys must be present in an aws_key.rb file.
  # Accepts as argument the filename to delete.
  # File is expected to be saved in the "uploads" folder in the feedbunch-#{Rails.env} bucket.

  def self.delete(filename)
    key = "uploads/#{filename}"
    Rails.logger.info "deleting S3 object with key #{key}"
    object = AWS::S3.new.buckets[Feedbunch::Application.config.s3_bucket].objects[key]
    object.delete
  end

end
