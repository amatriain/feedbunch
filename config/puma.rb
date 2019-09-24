# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i
threads threads_count, threads_count

# Specifies the `environment` that Puma will run in.
#
environment = ENV.fetch('RAILS_ENV') { 'development' }

# Specifies the `port` that Puma will listen on to receive requests, default is 3000.
# In production bind to a unix socket instead
#
if environment != 'production'
  port        ENV.fetch('PORT') { 3000 }
end

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY') { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
#
# preload_app!

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted this block will be run, if you are using `preload_app!`
# option you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, Ruby
# cannot share connections between processes.
#
# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Configuration only for production environment
if environment == 'production'
  # Bind to a unix socket instead of opening a port (a nginx server opens the port instead)
  bind 'unix:///tmp/feedbunch-puma.sock'

  # Set release directory so puma can pick up changes when running phased restarts
  directory '/var/rails/feedbunch/current'

  # Redirect output to logfile in production
  stdout_redirect '/var/log/feedbunch-puma.log'

  # Save a pidfile so init system can manage service
  pidfile '/tmp/feedbunch-puma.pid'
end