#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.5.2'
set :rvm_user_path, '~/.rvm'

#############################################################
#	Settings
#############################################################

set :format, :pretty
set :log_level, :info

# Map new commands we need during deployment
SSHKit.config.command_map[:puma] = 'sudo service feedbunch-puma'
SSHKit.config.command_map[:redis_cache] = 'sudo service redis-cache'
SSHKit.config.command_map[:redis_sidekiq] = 'sudo service redis-sidekiq'
SSHKit.config.command_map[:sidekiq] = 'sudo service sidekiq'

# Lazily evaluate :stage variable. It is given value in the stage files, which are ran after this one. This means
# that the value of :stage cannot be directly fetched in this file, but it can be lazily evaluated so that
# the value is retrieved after the stage file has run (and so the variable has value).
set :stage, proc{fetch :stage}

#############################################################
#	Servers
#############################################################

set :deploy_to, '/var/rails/feedbunch'
set :keep_releases, 5
set :linked_files, %w{
                      config/database.yml
                      config/secrets.yml
                      config/newrelic.yml
                      redis-cache/redis.conf
                      redis-sidekiq/redis.conf
                  }
set :linked_dirs, %w{
                      bin
                      log
                      uploads
                      public/assets
                      public/system
                      public/.well-known
                      tmp/cache
                      tmp/pids
                      tmp/sockets
                      vendor/bundle
                      rack_cache
                  }

#############################################################
#	Git
#############################################################

set :scm, :git
set :repo_url,  'git://github.com/amatriain/feedbunch.git'
# Default is to deploy master, but it can be overriden with REVISION or BRANCH_NAME env variables
set :branch, ENV['REVISION'] || ENV['BRANCH_NAME'] || 'master'

#############################################################
#	Puma
#############################################################

namespace :puma do

  desc 'Start Puma'
  task :start do
    on roles :app do
      execute :puma, 'start'
    end
  end

  desc 'Stop Puma'
  task :stop do
    on roles :app do
      execute :puma, 'stop'
    end
  end

  desc 'Restart Puma'
  task :restart do
    on roles :app do
      execute :puma, 'restart'
    end
  end

  desc 'Restart Puma with phased-restart. If there have been changes in the DB schema you MUST issue a stop+start manually.'
  task :phased_restart do
    on roles :app do
      within release_path do
        execute :bundle, :exec, :pumactl, '-F config/puma.rb', 'phased-restart'
      end
    end
  end

end

#############################################################
#	Redis backend for Rails cache
#############################################################

namespace :redis_cache do

  desc 'Start Redis backend for Rails cache'
  task :start do
    on roles :app do
      execute :redis_cache, 'start'
    end
  end

  desc 'Stop Redis backend for Rails cache'
  task :stop do
    on roles :app do
      execute :redis_cache, 'stop'
    end
  end

  desc 'Restart Redis backend for Rails cache'
  task :restart do
    invoke 'redis_cache:stop'
    invoke 'redis_cache:start'
  end

  desc 'Clear the Rails cache, removing all saved data from Redis'
  task :clear do
    on roles :app do
      within release_path do
        execute :rake, 'rails_cache:clear'
      end
    end
  end
end

#############################################################
#	Redis backend for Sidekiq
#############################################################

namespace :redis_sidekiq do

  desc 'Start Redis backend for Sidekiq'
  task :start do
    on roles :background do
      execute :redis_sidekiq, 'start'
    end
  end

  desc 'Stop Redis backend for Sidekiq'
  task :stop do
    on roles :background do
      execute :redis_sidekiq, 'stop'
    end
  end

  desc 'Restart Redis backend for Sidekiq'
  task :restart do
    invoke 'redis_sidekiq:stop'
    invoke 'redis_sidekiq:start'
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
    invoke 'puma:start'
    invoke 'redis_cache:start'
    invoke 'redis_sidekiq:start'
    invoke 'sidekiq:start'
  end

  desc 'Stop the application'
  task :stop do
    invoke 'puma:stop'
    invoke 'redis_cache:stop'
    invoke 'redis_sidekiq:stop'
    invoke 'sidekiq:stop'
  end

  desc 'Restart the application'
  task :restart do
    invoke 'puma:phased_restart'
    invoke 'sidekiq:restart'
  end

  # after deploying, restart the app
  after 'deploy:publishing', 'deploy:restart'

  # clean up old releases on each deploy, keep only 5 most recent releases
  after 'deploy:restart', 'deploy:cleanup'
end
