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

  # Declare sidekiq-cron jobs (sidekiq workers that must be run periodically)
  # cron format: (minute hour day-of-month month day-of-week)
  Sidekiq::Cron::Job.create name: 'Cleanup old signups - daily at 3AM',
                            cron: '0 3 * * *',
                            klass: 'CleanupSignupsWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Destroy old job states - daily at 4AM',
                            cron: '0 4 * * *',
                            klass: 'DestroyOldJobStatesWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Restore missing scheduled feed updates - daily at 6AM',
                            cron: '0 6 * * *',
                            klass: 'FixSchedulesWorker',
                            queue: :maintenance

  # The ResetDemoUserWorker only is scheduled if the demo user is enabled.
  # See config/initializers/demo_user.rb for demo user details.
  demo_enabled_str = ENV.fetch("DEMO_USER_ENABLED") { "true" }
  demo_enabled_str = demo_enabled_str.downcase.strip
  demo_enabled = ActiveRecord::Type::Boolean.new.cast demo_enabled_str
  if demo_enabled
    Sidekiq::Cron::Job.create name: 'Reset the demo user - hourly',
                              cron: '0 * * * *',
                              klass: 'ResetDemoUserWorker',
                              queue: :maintenance
  end

  Sidekiq::Cron::Job.create name: 'Update the statistics of the Rails cache - every 10 minutes',
                            cron: '*/10 * * * *',
                            klass: 'UpdateRedisCacheStatsWorker',
                            queue: :maintenance
end

Sidekiq.configure_client do |config|
  # Client needs 1 redis connection per process (see Puma config, num of process = num of Puma workers)
  config.redis = ConnectionPool.new size: 1, &redis_conn
end

# Show error backtraces
Sidekiq.default_worker_options = { 'backtrace' => true }
