# frozen_string_literal: true

# Replace libc-based DNS resolution with pure Ruby DNS resolution, to avoid locking the ruby interpreter
require 'resolv-replace'

# Create Redis connection
redis_conn = proc {
  Redis.new url: Rails.application.secrets.redis_sidekiq
}

# Redis server location
Sidekiq.configure_server do |config|
  # Server needs (concurrency + 2) redis connections
  config.redis = ConnectionPool.new size: 12, &redis_conn
end

Sidekiq.configure_client do |config|
  # Client needs 1 redis connection per process (see Puma config, num of process = num of Puma workers)
  config.redis = ConnectionPool.new size: 1, &redis_conn
end

# Show error backtraces
Sidekiq.default_worker_options = { 'backtrace' => true }
