# God configuration file
# From the rails root, execute:
# god -c config/background_jobs.god

# Rails environment defaults to development
rails_env = ENV['RAILS_ENV'] || 'development'

# Paths in staging, production environments are in the capistrano deployment folder.
# In other environments they are relative to the directory god is run from.
if %w{staging production}.include? rails_env
  app_root = File.join %w{/ var rails feedbunch current}
  log_path = File.join %w{/ var rails feedbunch shared log}
  God.pid_file_directory = File.join %w{/ var rails feedbunch shared tmp pids}
else
  app_root = Dir.pwd
  log_path = File.join app_root, 'log'
  God.pid_file_directory = File.join app_root, 'tmp', 'pids'
end

# Notifications config for God. This file will be different in production and staging environments.
God.load(File.join(app_root, 'config', 'notifications.god'))

God.watch do |w|
  if %w{staging production}.include? rails_env
    redis_path = File.join %w{/ var rails feedbunch shared redis}
  else
    redis_path = File.join app_root, 'redis'
  end

  w.name = 'redis-server'
  w.group = 'redis-server-group'
  w.start = "redis-server #{File.join(redis_path, 'redis.conf')}"
  w.stop = 'redis-cli -p 6379 shutdown'
  w.stop_timeout = 5.minutes

  # This is not necessary if redis.conf does not specify that redis should be daemonized
  #w.pid_file = File.join app_root, 'pids', 'redis.pid'
  #w.behavior :clean_pid_file

  # Uncomment one of the following two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabyte, cpu_max: 50.percent
  w.keepalive

  w.dir = redis_path
  w.log = File.join log_path, 'redis.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admins'
    end
  end
end

God.watch do |w|
  resque_env = ENV['RESQUE_ENV'] || 'app'

  w.name = 'resque-work'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'QUEUE' => 'update_feeds',
           'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => '300'}
  w.start = "rake -f #{File.join(app_root, 'Rakefile')} resque:work"
  w.stop_timeout = 5.minutes

  # Uncomment one of the following two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabytes, cpu_max: 50.percent
  w.keepalive

  w.dir = app_root
  w.log = File.join log_path, 'resque.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admins'
    end
  end
end

God.watch do |w|
  resque_env = ENV['RESQUE_ENV'] || 'app'

  w.name = 'resque-scheduler'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => ' 300',
           'DYNAMIC_SCHEDULE' => true
          }
  w.start = "rake -f #{File.join(app_root, 'Rakefile')} resque:scheduler"
  w.stop_timeout = 5.minutes

  # Uncomment one of the following two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabytes, cpu_max: 25.percent
  w.keepalive

  w.dir = app_root
  w.log = File.join log_path, 'resque.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admins'
    end
  end
end
