require 'resque/tasks'
require 'resque_scheduler/tasks'

namespace :resque do
  task setup: :environment do
    require 'resque'
    require 'resque_scheduler'
    require 'resque/scheduler'

    # If your schedule already has +queue+ set for each job, you don't
    # need to require your jobs.  This can be an advantage since it's
    # less code that resque-scheduler needs to know about. But in a small
    # project, it's usually easier to just include you job classes here.
    # So, something like this:
    #require 'jobs'
  end
end
