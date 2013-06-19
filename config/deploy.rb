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
set :repository,  'git://github.com/amatriain/feedbunch.git'
set :branch, 'master'
set :deploy_via, :remote_cache

#############################################################
#	Passenger
#############################################################

namespace :feedbunch_passenger do
  task :restart, roles: :app do
    # Tell passenger to restart the app
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

#############################################################
#	God (manages Redis, Resque)
#############################################################

namespace :feedbunch_god do
  task :start, roles: :background do
    run "cd #{current_path};
        RAILS_ENV=#{rails_env} RESQUE_ENV=background bundle exec god -c #{File.join(current_path,'config','background_jobs.god')}"
  end

  task :stop, roles: :background do
    # We run a "true" shell command after issuing a "god terminate" command because otherwise if
    # God were not running before this, we would get a return value of false which
    # Capistrano would intepret as an error and the deployment would be rolled back
    run "cd #{current_path};
        bundle exec god terminate;
        true"
  end

  task :restart, roles: :background do
    feedbunch_god.stop
    feedbunch_god.start
  end
end

#############################################################
#	Copy per-environment config files to deployment
#############################################################

namespace :feedbunch_secret_data do
  task :copy, roles: [:app, :background], except: {no_release: true} do

    run 'ln -sf /home/feedbunch/config/database.yml ' \
        "#{release_path}/config/database.yml"

    copy_app
    copy_background
  end

  task :copy_app, roles: :app do
    run 'ln -sf /home/feedbunch/config/secret_token.rb ' \
        "#{release_path}/config/initializers/secret_token.rb"

    run "ln -sf /home/feedbunch/config/#{rails_env}.rb " \
        "#{release_path}/config/environments/#{rails_env}.rb"
  end

  task :copy_background, roles: :background do
    run 'ln -sf /home/feedbunch/config/notifications.god ' \
        "#{release_path}/config/notifications.god"

    # Redis working directory is in the capistrano shared folder, so that the
    # append-only file and the dump file are not lost on each deployment. Create it if necessary.
    run "mkdir -p #{shared_path}/redis"

    run 'ln -sf /home/feedbunch/config/redis.conf ' \
        "#{release_path}/redis/redis.conf"
  end
end

#############################################################
#	Create and link "uploads" folder in the shared folder
#############################################################

namespace :feedbunch_shared_folders do
  task :create, roles: [:app, :background], except: {no_release: true} do
    # Uploads directory is in the capistrano shared folder, so that the
    # uploaded files are not lost on each deployment. Create it if necessary.
    run "mkdir -p #{shared_path}/uploads"
    run "ln -sfT #{shared_path}/uploads #{release_path}/uploads"
  end
end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do
  task :start, roles: :background, except: {no_release: true} do
    feedbunch_god.start
  end

  task :stop, roles: :background, except: {no_release: true} do
    feedbunch_god.stop
  end

  task :restart, roles: [:app, :background], except: {no_release: true} do
    feedbunch_god.restart
    feedbunch_passenger.restart
  end
end

# copy secret files just before compiling assets
before 'deploy:assets:precompile', 'feedbunch_secret_data:copy'

# Create shared folders after copying secret data
after 'feedbunch_secret_data:copy', 'feedbunch_shared_folders:create'

# run database migrations on each deploy, just after copying the new code
after 'deploy:update_code', 'deploy:migrate'

# clean up old releases on each deploy, keep only 5 most recent releases
after 'deploy:restart', 'deploy:cleanup'