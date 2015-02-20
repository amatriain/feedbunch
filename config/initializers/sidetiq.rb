# Log Sidetiq messages to the rails log
Sidetiq.logger = Rails.logger

# Set a very small handler pool size for sidetiq, to use as little resources as possible
Sidetiq.configure do |config|
  config.handler_pool_size = 1
end