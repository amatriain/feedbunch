#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_type, :system
set :rvm_ruby_version, 'ruby-2.0.0-p353'

#############################################################
#	Settings
#############################################################

set :format, :pretty
set :log_level, :debug

#############################################################
#	Servers
#############################################################

set :deploy_to, '/var/rails/feedbunch'
set :keep_releases, 5

# TODO: use the linked_files setting instead of manually running a "ln -s" command below for each secret file
# set :linked_files, %w{config/database.yml}
# TODO: use the linked_dirs setting instead of manually creating and linking the uploads and god_pid folders below
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

#############################################################
#	Git
#############################################################

set :scm, :git
set :repo_url,  'git://github.com/amatriain/feedbunch.git'
set :branch, 'master'

#############################################################
#	Passenger
#############################################################

namespace :feedbunch_passenger do
  desc 'Restart passenger-deployed application'
  task :restart do
    on roles :app do
      # Tell passenger to restart the app
      execute :touch, File.join(current_path,'tmp','restart.txt')
    end
  end
end

#############################################################
#	God (manages Redis, Resque)
#############################################################

namespace :feedbunch_god do
  desc 'Start God-managed tasks: Redis, Resque'
  task :start do
    on roles :background do
      execute "cd #{current_path};
        RAILS_ENV=#{fetch(:rails_env)} RESQUE_ENV=background bundle exec god -c #{File.join(current_path,'config','background_jobs.god')} --log #{shared_path}/log/god.log"
    end
  end

  desc 'Stop God-managed tasks: Redis, Resque'
  task :stop do
    on roles :background do
      # We run a "true" shell command after issuing a "god terminate" command because otherwise if
      # God were not running before this, we would get a return value of false which
      # Capistrano would intepret as an error and the deployment would be rolled back
      execute "cd #{current_path};
        bundle exec god terminate;
        true"
    end
  end

  desc 'Restart God-managed tasks: Redis, Resque'
  task :restart do
    on roles :background do
      feedbunch_god.stop
      feedbunch_god.start
    end
  end
end

#############################################################
#	Copy per-environment config files to deployment
#############################################################

namespace :feedbunch_secret_data do
  
  desc 'Copy secret files in all servers'
  task :copy do
    on roles :app, :background do
      execute "ln -sf /home/feedbunch/config/#{fetch(:rails_env)}.rb " \
        "#{release_path}/config/environments/#{fetch(:rails_env)}.rb"

      execute 'ln -sf /home/feedbunch/config/database.yml ' \
        "#{release_path}/config/database.yml"

      execute 'ln -sf /home/feedbunch/config/resque.yml ' \
        "#{release_path}/config/resque.yml"

      execute 'ln -sf /home/feedbunch/config/aws_key.rb ' \
        "#{release_path}/config/initializers/aws_key.rb"

      execute 'ln -sf /home/feedbunch/config/devise.rb ' \
        "#{release_path}/config/initializers/devise.rb"

      execute 'feedbunch_secret_data:copy_app'
      copy_background
    end
  end

  desc 'Copy secret files in web servers'
  task :copy_app do
    on roles :app do
      execute 'ln -sf /home/feedbunch/config/secret_token.rb ' \
        "#{release_path}/config/initializers/secret_token.rb"
    end
  end

  desc 'Copy secret files in background servers'
  task :copy_background do
    on roles :background do
      run 'ln -sf /home/feedbunch/config/notifications.god ' \
        "#{release_path}/config/notifications.god"

      # Redis working directory is in the capistrano shared folder, so that the
      # append-only file and the dump file are not lost on each deployment. Create it if necessary.
      run "mkdir -p #{shared_path}/redis"

      run 'ln -sf /home/feedbunch/config/redis.conf ' \
        "#{release_path}/redis/redis.conf"
    end
  end

  # Create shared folders after copying secret data
  after :copy, 'feedbunch_shared_folders:create'
end

#############################################################
#	Create and link "uploads" and "tmp/pids" folder in the shared folder.
# "uploads" is created in both server roles, "tmp/pids" only in the background server.
#############################################################

namespace :feedbunch_shared_folders do

  desc 'Create uploads folder in shared folder and link it into the current folder'
  task :create_uploads_folder do
    on roles :app, :background do
      # Uploads directory is in the capistrano shared folder, so that the
      # uploaded files are not lost on each deployment. Create it if necessary.
      run "mkdir -p #{shared_path}/uploads"
      run "rm -rf #{release_path}/uploads"
      run "ln -sf #{shared_path}/uploads #{release_path}/uploads"
    end
  end

  desc 'Create folder for the God PID in shared folder and link it into the current folder'
  task :create_god_pid_folder do
    on roles :background do
      # God PIDs directory is in the capistrano shared folder, so that the
      # PID files are not lost on each deployment. Create it if necessary.
      run "mkdir -p #{shared_path}/tmp/pids"
      run "rm -rf #{release_path}/tmp"
      run "ln -sf #{shared_path}/tmp #{release_path}/tmp"
    end
  end

  desc 'Create shared folders and link them into the current folder'
  task :create do
    on roles :app, :background do
      create_uploads_folder
      create_god_pid_folder
    end
  end
end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do

  desc 'Start the application'
  task :start do
    on roles :app, :background do
      feedbunch_god.start
    end
  end

  desc 'Stop the application'
  task :stop do
    on roles :app, :background do
      feedbunch_god.stop
    end
  end

  desc 'Restart the application'
  task :restart do
    on roles :app, :background do
      feedbunch_god.restart
      feedbunch_passenger.restart
    end
  end

  # copy secret files just before compiling assets
  before 'assets:precompile', 'feedbunch_secret_data:copy'

  # clean up old releases on each deploy, keep only 5 most recent releases
  after :restart, :cleanup
end



# Task definition example:
#
#namespace :deploy do
#
#  desc 'Restart application'
#  task :restart do
#    on roles(:app), in: :sequence, wait: 5 do
#      # Your restart mechanism here, for example:
#      # execute :touch, release_path.join('tmp/restart.txt')
#    end
#  end
#
#  after :restart, :clear_cache do
#    on roles(:web), in: :groups, limit: 3, wait: 10 do
#      # Here we can do anything such as:
#      # within release_path do
#      #   execute :rake, 'cache:clear'
#      # end
#    end
#  end
#
#  after :finishing, 'deploy:cleanup'
#
#end
