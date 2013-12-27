#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.1.0'

#############################################################
#	Settings
#############################################################

set :format, :pretty
set :log_level, :debug
SSHKit.config.command_map[:god] = 'bundle exec god'

#############################################################
#	Servers
#############################################################

set :deploy_to, '/var/rails/feedbunch'
set :keep_releases, 5
set :linked_files, %w{
                      config/database.yml
                      config/notifications.god
                      config/resque.yml
                      config/environments/staging.rb
                      config/environments/production.rb
                      config/initializers/aws_key.rb
                      config/initializers/devise.rb
                      config/initializers/secret_token.rb
                      redis/redis.conf
                  }
set :linked_dirs, %w{
                      bin
                      log
                      uploads
                      public/assets
                      public/system
                      tmp/cache
                      tmp/pids
                      tmp/sockets
                      vendor/bundle
                  }

#############################################################
#	Git
#############################################################

set :scm, :git
set :repo_url,  'git://github.com/amatriain/feedbunch.git'
set :branch, 'master'

#############################################################
#	God (manages Redis, Resque)
#############################################################

namespace :feedbunch_god do

  desc 'Start God and God-managed tasks: Redis, Resque'
  task :start do
    on roles :background do
      within current_path do
        with resque_env: 'background' do
          execute :god, '-c', File.join(current_path,'config','background_jobs.god'),
                  '--log', File.join(shared_path, 'log', 'god.log')
        end
      end
    end
  end

  desc 'Stop God and God-managed tasks: Redis, Resque'
  task :stop do
    on roles :background do
      within current_path do
        # We run a "true" shell command after issuing a "god terminate" command because otherwise if
        # God were not running before this, we would get a return value of false which
        # Capistrano would intepret as an error and the deployment would be rolled back
        execute :god, 'terminate', ';true'
      end
    end
  end

  desc 'Restart God and God-managed tasks: Redis, Resque'
  task :restart_all do
    invoke 'feedbunch_god:stop'
    invoke 'feedbunch_god:start'
  end

  desc 'Restart only Resque watches (resque-worker, resque-scheduler)'
  task :restart_resque do
    on roles :background do
      within current_path do
        with resque_env: 'background' do
          # terminate the god process without terminating any god-watched processes
          execute :god, 'quit'
          # start again the god process
          execute :god, '-c', File.join(current_path,'config','background_jobs.god'),
                  '--log', File.join(shared_path, 'log', 'god.log')
          # restart only watches in resque-group group
          execute :god, 'restart', 'resque-group'
        end
      end
    end
  end
end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do

  desc 'Start the application'
  task :start do
    invoke 'feedbunch_god:start'
  end

  desc 'Stop the application'
  task :stop do
    invoke 'feedbunch_god:stop'
  end

  desc 'Restart the application'
  task :restart do
    on roles :web do
      within File.join(current_path,'tmp') do
        # Tell passenger to restart the app
        execute :touch, 'restart.txt'
      end
    end
    invoke 'feedbunch_god:restart_resque'
  end

  # clean up old releases on each deploy, keep only 5 most recent releases
  after 'deploy:restart', 'deploy:cleanup'
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
