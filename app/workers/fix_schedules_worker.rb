require 'schedule_manager'

##
# Background job to fix the schedule for feed updates. Any missing
# schedule will be added to Sidekiq.
#
# This serves as safeguard against schedules getting lost for any reason.
#
# This is a Sidekiq worker

class FixSchedulesWorker
  include Sidekiq::Worker

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

  ##
  # Fix feed update schedules. Any feed which does not have scheduled updates
  # will be detected, and the missing scheduled update for the feed will be
  # added to Sidekiq.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    ScheduleManager.fix_scheduled_updates
  end
end