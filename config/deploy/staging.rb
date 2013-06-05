#############################################################
#	Settings
#############################################################

server 'staging.feedbunch.com', :app, :web, :db, primary: true
ssh_options[:keys] = '/home/amatriain/Feedbunch/Staging/Openreaderstaging.pem'
set :rails_env, :staging