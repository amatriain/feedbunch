require 'schedule_manager'

##
# Background job to fix the schedule for feed updates. Any missing
# schedule will be added to resque-schedule.
#
# Recent resque-scheduler versions wipe all dynamic schedules
# when restarting. This means all feed update schedules, which are dynamically
# added via the API, are wiped on each application redeployment. The fix for
# this highly undesirable (for me) behavior is to make this job part of a
# static schedule (see config/initializers/resque.rb and config/static_schedule.yml).
# This job will be scheduled to run every hour even after restarting resque-schedule,
# and will add back the scheduled feed updates that were wiped on restart. It
# also serves as safeguard against schedules getting lost for any reason.
#
# For more detail about this unfortunate behavior of resque-scheduler see:
#
#   https://github.com/resque/resque-scheduler/issues/269
#
# This is a Sidekiq worker

class FixSchedulesWorker
  include Sidekiq::Worker

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

  ##
  # Fix feed update schedules. Any feed which does not have scheduled updates
  # will be detected, and the missing scheduled update for the feed will be
  # added to resque-schedule.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    ScheduleManager.fix_update_schedules
  end
end