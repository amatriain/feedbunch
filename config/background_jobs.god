# God configuration file
# From the rails root, execute:
# god -c config/background_jobs.god

# IMPORTANT! all paths are relative to this path, which defaults to the directory god is called from.
# Therefore god MUST be called from the rails root, or all paths in this file will be incorrect.
APP_ROOT = Dir.pwd

# Notifications config for God. This file will be different in production and staging environments.
God.load(File.join(APP_ROOT, 'config', 'notifications.god'))

God.watch do |w|
  w.name = 'redis'
  w.group = 'background'
  w.start = "redis-server #{File.join(APP_ROOT, 'redis', 'redis.conf')}"
  w.stop = 'redis-cli -p 6379 shutdown'

  # This is not necessary if redis.conf does not specify that redis should be daemonized
  #w.pid_file = File.join APP_ROOT, 'pids', 'redis.pid'
  #w.behavior :clean_pid_file

  # Uncomment one of the followint two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabyte, cpu_max: 50.percent
  w.keepalive

  w.dir = APP_ROOT
  w.log = File.join APP_ROOT, 'log', 'redis.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admin'
    end
  end
end

God.watch do |w|
  w.name = 'resque-work'
  w.group = 'background'
  w.env = {'QUEUE' => 'update_feeds',
           'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => ' 10'}
  w.start = "rake -f #{File.join(APP_ROOT, 'Rakefile')} resque:work"

  # Uncomment one of the followint two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabytes, cpu_max: 50.percent
  w.keepalive

  w.dir = APP_ROOT
  w.log = File.join APP_ROOT, 'log', 'resque.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admin'
    end
  end
end

God.watch do |w|
  w.name = 'resque-scheduler'
  w.group = 'background'
  w.env = {'TERM_CHILD' => '1',
           'RESQUE_TERM_TIMEOUT' => ' 10'}
  w.start = "rake -f #{File.join(APP_ROOT, 'Rakefile')} resque:scheduler"

  # Uncomment one of the followint two lines, depending on whether resource usage limit is desired
  #w.keepalive memory_max: 256.megabytes, cpu_max: 25.percent
  w.keepalive

  w.dir = APP_ROOT
  w.log = File.join APP_ROOT, 'log', 'resque.log'

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.times = 5
      c.within = 5.minute
      c.to_state = [:start, :restart]
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = 'admin'
    end
  end
end

