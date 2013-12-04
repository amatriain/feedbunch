#############################################################
#	Settings
#############################################################

server 'staging.feedbunch.com', :app, :web, :db, primary: true
server 'background.staging.feedbunch.com', :background
ssh_options[:keys] = '/home/amatriain/Feedbunch/Staging/Openreaderstaging.pem'
set :rails_env, 'staging'