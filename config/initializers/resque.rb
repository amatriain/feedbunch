require 'resque'
require 'yaml'

# Resque-scheduler additions to resque-web
require 'resque_scheduler'
require 'resque_scheduler/server'

# For each Rails environment (production and staging) there are two different server roles; background servers
# connect to Redis on localhost, while app servers connect to the Redis instance in the background server.
rails_root = ENV['RAILS_ROOT'] || __dir__ + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
resque_env = ENV['RESQUE_ENV'] || 'app'

if resque_env=='background'
  resque_conf_key = "#{rails_env}_background"
else
  resque_conf_key = rails_env
end
resque_config = YAML.load_file(rails_root.to_s + '/config/resque.yml')
Resque.redis = resque_config[resque_conf_key]

# In background servers we must require each job class individually, because we're not
# running the full Rails app
if resque_env=='background'
  require "#{rails_root}/app/jobs/fetch_imported_feed_job"
  require "#{rails_root}/app/jobs/import_subscriptions_job"
  require "#{rails_root}/app/jobs/schedule_feed_updates_job"
  require "#{rails_root}/app/jobs/update_feed_job"
end

# If you want to be able to dynamically change the schedule,
# uncomment this line.  A dynamic schedule can be updated via the
# Resque::Scheduler.set_schedule (and remove_schedule) methods.
# When dynamic is set to true, the scheduler process looks for
# schedule changes and applies them on the fly.
# Note: This feature is only available in >=2.0.0.
# IMPORTANT: this line MUST BE ABOVE the "Resque.schedule = YAML.load_file..." line.
Resque::Scheduler.dynamic = true

# The schedule doesn't need to be stored in a YAML, it just needs to
# be a hash.  YAML is usually the easiest.
#Resque.schedule = YAML.load_file(rails_root.to_s + '/config/job_schedule.yml')

Resque.before_fork do |job|
  # Reconnect to the DB before running each job. Otherwise we get errors if the DB
  # is restarted after starting Resque.
  # Absolutely necessary on Heroku, otherwise we get a "PG::Error: SSL SYSCALL error: EOF detected" exception
  ActiveRecord::Base.establish_connection
end