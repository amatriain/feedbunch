#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.1.3'
set :rvm_user_path, '~/.rvm'

#############################################################
#	Settings
#############################################################

set :format, :pretty
set :log_level, :warn
SSHKit.config.command_map[:redis] = 'sudo service redis'
SSHKit.config.command_map[:sidekiq] = 'sudo service sidekiq'

#############################################################
#	Servers
#############################################################

set :deploy_to, '/var/rails/feedbunch'
set :keep_releases, 5
set :linked_files, %w{
                      config/database.yml
                      config/secrets.yml
                      config/newrelic.yml
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
#	Redis
#############################################################

namespace :redis do

  desc 'Start Redis'
  task :start do
    on roles :background do
      execute :redis, 'start'
    end
  end

  desc 'Stop Redis'
  task :stop do
    on roles :background do
      execute :redis, 'stop'
    end
  end

  desc 'Restart Redis'
  task :restart do
    invoke 'redis:stop'
    invoke 'redis:start'
  end
end

#############################################################
#	Sidekiq
#############################################################

namespace :sidekiq do

  desc 'Start Sidekiq'
  task :start do
    on roles :background do
      execute :sidekiq, 'start'
    end
  end

  desc 'Stop Sidekiq'
  task :stop do
    on roles :background do
      execute :sidekiq, 'stop'
    end
  end

  desc 'Restart Sidekiq'
  task :restart do
    on roles :background do
      execute :sidekiq, 'restart'
    end
  end

end

#############################################################
#	Deployment start/stop/restart hooks
#############################################################

namespace :deploy do

  desc 'Start the application'
  task :start do
    invoke 'redis:start'
    invoke 'sidekiq:start'
  end

  desc 'Stop the application'
  task :stop do
    invoke 'redis:stop'
    invoke 'sidekiq:stop'
  end

  desc 'Restart the application'
  task :restart do
    on roles :web do
      within File.join(current_path,'tmp') do
        # Tell passenger to restart the app
        execute :touch, 'restart.txt'
      end
    end
    invoke 'sidekiq:restart'
  end

  # after deploying, restart the Passenger app
  after 'deploy:publishing', 'deploy:restart'

  # clean up old releases on each deploy, keep only 5 most recent releases
  after 'deploy:restart', 'deploy:cleanup'

  # record deployments in NewRelic
  after 'deploy:updated', 'newrelic:notice_deployment'
end
