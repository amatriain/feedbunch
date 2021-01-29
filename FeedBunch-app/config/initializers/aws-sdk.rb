# frozen_string_literal: true

if Rails.env == 'production'
  require 'aws-sdk-s3'

  # AWS log level defaults to :info, you can set a different level here
  #Aws.config[:log_level] = :debug

  # Configure AWS credentials
    access_key = Rails.application.secrets.aws_access_key_id
    secret = Rails.application.secrets.aws_secret_access_key
    Aws.config[:credentials] = Aws::Credentials.new access_key, secret
    Aws.config[:region] = Rails.application.secrets.aws_region

  # Name of the S3 bucket for storing objects. Can be changed with the AWS_S3_BUCKET
  # environment variable, by default takes the value "feedbunch-<environment>",
  # e.g. "feedbunch-production" in the production environment
    s3_bucket = ENV.fetch("AWS_S3_BUCKET") { "feedbunch-#{Rails.env}" }
    Feedbunch::Application.config.s3_bucket = s3_bucket
end
