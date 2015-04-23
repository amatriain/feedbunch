require 'signups_manager'

##
# Background job to clean up data related to signups.
#
# This is a Sidekiq worker

class CleanupSignupsWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance
  # Run daily at 3 AM. Missed runs are executed immediately
  recurrence backfill: true do
    daily.hour_of_day 3
  end

  ##
  # Clean up outdated signup data in the db:
  # - old unconfirmed signups are removed from the db. The interval after which invitations are discarded
  # is configurable
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    SignupsManager.send_first_confirmation_reminders
    SignupsManager.destroy_old_signups
  end
end