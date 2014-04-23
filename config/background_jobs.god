# God configuration file
# From the rails root, execute:
# god -c config/background_jobs.god

#############################################################
#	God basic configuration
#############################################################

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

#############################################################
#	Email notifications
#############################################################

# A bit of monkeypatching for SMTP notifications to work with STARTTLS.
Net::SMTP.class_eval do
  def initialize_with_starttls(*args)
    initialize_without_starttls(*args)
    enable_starttls_auto
  end

  alias_method :initialize_without_starttls, :initialize
  alias_method :initialize, :initialize_with_starttls
end

# Load secrets for the current Rails environment.
# The Rails.application.secrets API cannot be used because God itself does not load a full Rails environment.
secrets_file = YAML.load_file File.join(app_root, 'config', 'secrets.yml')
secrets = secrets_file[rails_env]

# Email notifications defaults.
# In production and staging notifications are sent via SMTP.
# In other environments notifications are sent via sendmail (normally to root@localhost)
God::Contacts::Email.defaults do |d|
  d.from_email = "god.#{rails_env}@feedbunch.com"
  d.from_name = "God #{rails_env.upcase}"

  if %w{production staging}.include? rails_env
    d.delivery_method = :smtp
    d.server_host = secrets['smtp_address']
    d.server_domain = secrets['smtp_address']
    d.server_auth = :login
    d.server_user = secrets['smtp_user_name']
    d.server_password = secrets['smtp_password']
  else
    d.delivery_method = :sendmail
  end

end

God.contact(:email) do |c|
  c.name = secrets['god_contact_name']
  c.group = 'admins'
  c.to_email = secrets['god_contact_email']
end

#############################################################
#	God watch - Redis-server
#############################################################

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

#############################################################
#	God watch - Resque workers
#############################################################

God.watch do |w|
  resque_env = ENV['RESQUE_ENV'] || 'app'

  w.name = 'resque-work-update_feeds'
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

  w.name = 'resque-work-maintenance'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'QUEUE' => 'maintenance',
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

  w.name = 'resque-work-subscriptions'
  w.group = 'resque-group'
  w.env = {'RAILS_ENV' => rails_env,
           'RESQUE_ENV' => resque_env,
           'QUEUE' => 'subscriptions',
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

#############################################################
#	God watch - Resque-scheduler
#############################################################

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
