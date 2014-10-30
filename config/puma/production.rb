directory '/var/rails/feedbunch/current'
environment 'production'
threads 4,4 
bind 'unix:///tmp/feedbunch-puma.sock'
workers 2
pidfile '/tmp/feedbunch-puma.pid'
stdout_redirect '/var/log/feedbunch-puma.log'
