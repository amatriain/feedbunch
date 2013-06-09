#############################################################
#	Multi-staging
#############################################################

set :stages, %w(production staging)
set :default_stage, 'staging'
require 'capistrano/ext/multistage'

#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_ruby_string, 'ruby-1.9.3-p429@feedbunch'
set :rvm_type, :system
require 'rvm/capistrano'

#############################################################
#	Settings
#############################################################

# runs 'bundle install' during deployment
require 'bundler/capistrano'

# precompiles assets in production
load 'deploy/assets'

default_environment['TERM'] = 'xterm'

#############################################################
#	Servers
#############################################################

set :user, 'feedbunch'
# We use a non-privileged user for security reasons
set :use_sudo, false
set :deploy_to, '/var/rails/feedbunch'

#############################################################
#	Git
#############################################################

set :scm, :git
set :repository,  'git://github.com/amatriain/openreader.git'
set :branch, 'master'
set :deploy_via, :remote_cache

#############################################################
#	Passenger
#############################################################

namespace :feedbunch_passenger do
  task :restart do
    # Tell passenger to restart the app
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

#############################################################
#	God (manages Redis, Resque)
#############################################################

namespace :feedbunch_god do
  task :start do
    run "cd #{current_path};
        RAILS_ENV=#{rails_env} bundle exec god -c #{File.join(current_path,'config','background_jobs.god')}"
  end

  task :stop do
    # We run a "true" shell command after issuing a "god terminate" command because otherwise if
    # God were not running before this, we would get a return value of false which
    # Capistrano would intepret as an error and the deployment would be rolled back
    run "cd #{current_path};
        bundle exec god terminate;
        true"
  end

  task :restart do
    feedbunch_god.stop
    feedbunch_god.start
  end
end

#############################################################
#	Copy per-environment config files to deployment
#############################################################

namespace :feedbunch_secret_data do
  task :copy, roles: :app, except: {no_release: true} do
    run 'ln -sf /home/feedbunch/config/secret_token.rb ' \
        "#{release_path}/config/initializers/secret_token.rb"

    run 'ln -sf /home/feedbunch/config/database.yml ' \
        "#{release_path}/config/database.yml"

    run "ln -sf /home/feedbunch/config/#{rails_env}.rb " \
        "#{release_path}/config/environments/#{rails_env}.rb"

    run 'ln -sf /home/feedbunch/config/notifications.god ' \
        "#{release_path}/config/notifications.god"

    # Redis working directory is in the capistrano shared folder, so that the
    # append-only file and the dump file are not lost on each deployment. Create it if necessary.
    redis_working_dir = File.join(shared_path, 'redis').gsub('/', '\\/')
    run "mkdir -p #{redis_working_dir}"

    run 'ln -sf /home/feedbunch/config/redis.conf ' \
        "#{shared_path}/redis/redis.conf"
  end
end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do
  task :start, roles: :app, except: {no_release: true} do
    feedbunch_god.start
  end

  task :stop, roles: :app, except: {no_release: true} do
    feedbunch_god.stop
  end

  task :restart, roles: :app, except: {no_release: true} do
    feedbunch_god.restart
    feedbunch_passenger.restart
  end
end

# copy secret files just before compiling assets
before 'deploy:assets:precompile', 'feedbunch_secret_data:copy'

# run database migrations on each deploy, just after copying the new code
after 'deploy:update_code', 'deploy:migrate'

# clean up old releases on each deploy, keep only 5 most recent releases
after 'deploy:restart', 'deploy:cleanup'