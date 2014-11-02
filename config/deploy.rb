#############################################################
#	Application
#############################################################

set :application, 'feedbunch'

#############################################################
#	RVM
#############################################################

set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.1.4'
set :rvm_user_path, '~/.rvm'

#############################################################
#	Settings
#############################################################

set :format, :pretty
set :log_level, :info

# Map new commands we need during deployment
SSHKit.config.command_map[:puma] = 'sudo service feedbunch-puma'
SSHKit.config.command_map[:redis] = 'sudo service redis'
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
        execute :bundle, :exec, :pumactl, "-F config/puma/#{fetch :stage}.rb", 'phased-restart'
      end
    end
  end

end

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
    invoke 'puma:start'
    invoke 'redis:start'
    invoke 'sidekiq:start'
  end

  desc 'Stop the application'
  task :stop do
    invoke 'puma:stop'
    invoke 'redis:stop'
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

  # record deployments in NewRelic
  after 'deploy:updated', 'newrelic:notice_deployment'
end
