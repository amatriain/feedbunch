load 'deploy/assets'
require "bundler/capistrano"

set :application, 'openreader'
set :repository,  'git://github.com/amatriain/openreader.git'
set :scm, :git
set :deploy_via, :remote_cache
set :deploy_to, '/var/rails/openreader'
default_environment['TERM'] = 'xterm'

set :rvm_ruby_string, 'ruby-1.9.3-p429@openreader'
require 'rvm/capistrano'
set :rvm_type, :system
set :rvm_path, '/usr/local/rvm'

server 'ec2-54-216-109-28.eu-west-1.compute.amazonaws.com', :app, :web, :db, primary: true
set :user, 'ubuntu'
ssh_options[:keys] = '/home/amatriain/Openreader/Staging/Openreaderstaging.pem'
set :rails_env, :staging

namespace :openreader_secret_data do
  task :copy, roles: :app, except: {no_release: true} do
    run 'ln -sf /home/ubuntu/Openreader/Staging/secret_token.rb ' \
        '#{release_path}/config/initializers/secret_token.rb'
    run 'ln -sf /home/ubuntu/Openreader/Staging/database.yml ' \
        "#{release_path}/config/database.yml"
  end
end

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

# copy secret files just before running database migrations
before 'deploy:assets:precompile', 'openreader_secret_data:copy'

# run database migrations on each deploy, just after copying the new code
after 'deploy:update_code', 'deploy:migrate'

# clean up old releases on each deploy, keep only 5 most recent releases
after 'deploy:restart', 'deploy:cleanup'