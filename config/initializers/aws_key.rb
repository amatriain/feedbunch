# load the libraries
require 'aws-sdk'

# log requests using the default rails logger
AWS.config logger: Rails.logger

AWS.config(
  access_key_id: Rails.application.secrets.aws_access_key_id,
  secret_access_key: Rails.application.secrets.aws_secret_access_key
)

# Name of the S3 bucket for storing objects. Different for each environment.
Feedbunch::Application.config.s3_bucket = "feedbunch-#{Rails.env}"