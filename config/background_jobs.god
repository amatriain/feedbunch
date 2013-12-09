# God configuration file
# From the rails root, execute:
# god -c config/background_jobs.god

# IMPORTANT! all paths are relative to this path, which defaults to the directory god is called from.
# Therefore god MUST be called from the rails root if $APP_ROOT is not set, or all paths in this file will be incorrect.
app_root = ENV['APP_ROOT'] || Dir.pwd

# Where God should put pid files for those watches it daemonizes
pid_path = ENV['PID_PATH'] || File.join(app_root, 'tmp', 'pids')
God.pid_file_directory = pid_path

# Notifications config for God. This file will be different in production and staging environments.
God.load(File.join(app_root, 'config', 'notifications.god'))

# Pass current environment to processes that need it
rails_env = ENV['RAILS_ENV'] || 'development'
resque_env = ENV['RESQUE_ENV'] || 'app'
log_path = ENV['LOG_PATH'] || File.join(app_root, 'log')

God.watch do |w|
  redis_path = ENV['REDIS_PATH'] || File.join(app_root, 'redis')

  w.name = 'redis-server'
  w.group = 'redis-server-group'
  w.start = "redis-server #{File.join(redis_path, 'redis.conf')}"
  w.stop = 'redis-cli -p 6379 shutdown'

  # This is not necessary if redis.conf does not specify that redis should be daemonized
  #w.pid_file = File.join app_root, 'pids', 'redis.pid'
  #w.behavior :clean_pid_file

  # Uncomment one of the following two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabyte, cpu_max: 50.percent
  w.keepalive

  w.dir = app_root
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
  w.name = 'resque-work'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'QUEUE' => 'update_feeds',
           'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => '300'}
  w.start = "rake -f #{File.join(app_root, 'Rakefile')} resque:work"

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
  w.name = 'resque-scheduler'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => ' 300'}
  w.start = "rake -f #{File.join(app_root, 'Rakefile')} resque:scheduler"

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
