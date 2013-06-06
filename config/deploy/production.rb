#############################################################
#	Settings
#############################################################

server 'production.feedbunch.com', :app, :web, :db, primary: true
ssh_options[:keys] = '/home/amatriain/Feedbunch/Production/Openreaderproduction.pem'
set :rails_env, :production