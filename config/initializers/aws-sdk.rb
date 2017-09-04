require 'aws-sdk-s3'

# AWS log level defaults to :info, you can set a different level here
#Aws.config[:log_level] = :debug

# Configure AWS credentials
access_key = Rails.application.secrets.aws_access_key_id
secret = Rails.application.secrets.aws_secret_access_key
Aws.config[:credentials] = Aws::Credentials.new access_key, secret
Aws.config[:region] = 'eu-west-1'

# Name of the S3 bucket for storing objects. Different for each environment.
Feedbunch::Application.config.s3_bucket = "feedbunch-#{Rails.env}"