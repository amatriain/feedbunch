# Replace libc-based DNS resolution with pure Ruby DNS resolution, to avoid locking the ruby interpreter
require 'resolv-replace'

# Redis server location
Sidekiq.configure_server do |config|
  # Server needs (concurrency + 2) redis connections
  config.redis = { url: Rails.application.secrets.redis_sidekiq, size: 5 }
end

Sidekiq.configure_client do |config|
  # Client needs 1 redis connection per process (see Puma config, num of process = num of Puma workers)
  config.redis = { url: Rails.application.secrets.redis_sidekiq, size: 1 }
end

# Show error backtraces
Sidekiq.default_worker_options = { 'backtrace' => true }

# Log Sidetiq messages to the rails log
Sidetiq.logger = Rails.logger