# load the libraries
require 'aws-sdk'

# log requests using the default rails logger
AWS.config logger: Rails.logger

AWS.config(
  access_key_id: 'YOUR-ACCESS-KEY-HERE',
  secret_access_key: 'YOUR-SECRET-ACCESS-KEY-HERE'
)

# Name of the S3 bucket for storing objects. Different for each environment.
Feedbunch::Application.config.s3_bucket = "feedbunch-#{Rails.env}"