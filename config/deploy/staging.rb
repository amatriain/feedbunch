#############################################################
#	Settings
#############################################################

server 'staging.feedbunch.com', :app, :web, :db, primary: true
set :rails_env, :staging