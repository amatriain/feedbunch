#############################################################
#	Multi-staging
#############################################################

set :stages, %w(production staging)
set :default_stage, 'staging'
require 'capistrano/ext/multistage'

#############################################################
#	Application
#############################################################

set :application, 'openreader'

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

set :user, 'openreader'
# We use a non-privileged user for security reasons
set :use_sudo, false
ssh_options[:keys] = '/home/amatriain/Openreader/Staging/Openreaderstaging.pem'
set :deploy_to, '/var/rails/openreader'

#############################################################
#	Git
#############################################################

set :scm, :git
set :repository,  'git://github.com/amatriain/openreader.git'
set :branch, 'master'
set :deploy_via, :remote_cache

#############################################################
#	RVM
#############################################################

set :rvm_ruby_string, 'ruby-1.9.3-p429@openreader'
require 'rvm/capistrano'
set :rvm_type, :system
set :rvm_path, '/usr/local/rvm'

#############################################################
#	Passenger
#############################################################

namespace :openreader_passenger do
  task :restart do
    # Tell passenger to restart the app
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

#############################################################
#	Copy secret token and database credentials to deployment
#############################################################

namespace :openreader_secret_data do
  task :copy, roles: :app, except: {no_release: true} do
    run 'ln -sf /home/openreader/config/secret_token.rb ' \
        "#{release_path}/config/initializers/secret_token.rb"
    run 'ln -sf /home/openreader/config/database.yml ' \
        "#{release_path}/config/database.yml"
    run 'ln -sf /home/openreader/config/staging.rb ' \
        "#{release_path}/config/environments/staging.rb"
  end
end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do
  task :restart, roles: :app, except: {no_release: true} do
    openreader_passenger.restart
  end
end

# copy secret files just before compiling assets
before 'deploy:assets:precompile', 'openreader_secret_data:copy'

# run database migrations on each deploy, just after copying the new code
after 'deploy:update_code', 'deploy:migrate'

# clean up old releases on each deploy, keep only 5 most recent releases
after 'deploy:restart', 'deploy:cleanup'