directory '/var/rails/feedbunch/current'
environment 'production'
threads 8,8 
bind 'unix:///tmp/feedbunch_puma.sock'
workers 2
pidfile '/tmp/feedbunch_puma.pid'
stdout_redirect '/var/log/feedbunch_puma.log'
