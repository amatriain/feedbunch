# Redis server location
Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_background }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_web }
end

# Show error backtraces
Sidekiq.default_worker_options = { 'backtrace' => true }

# Log Sidetiq messages to the rails log
Sidetiq.logger = Rails.logger