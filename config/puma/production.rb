directory '/var/rails/feedbunch/current'
environment 'production'
threads 8,8 
bind 'unix:///tmp/feedbunch-puma.sock'
workers 2
daemonize true
pidfile '/tmp/feedbunch-puma.pid'
stdout_redirect '/var/log/feedbunch-puma.log'
