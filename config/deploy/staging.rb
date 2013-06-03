#############################################################
#	Settings
#############################################################

server 'ec2-54-216-109-28.eu-west-1.compute.amazonaws.com', :app, :web, :db, primary: true
set :rails_env, :staging