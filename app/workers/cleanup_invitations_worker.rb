require 'invitations_manager'

##
# Background worker to clean up data related to invitations.
#
# This is a Sidekiq worker

class CleanupInvitationsWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance
  # Run daily at 2 AM. Missed runs are executed immediately
  recurrence backfill: true do
    daily.hour_of_day 2
  end

  ##
  # Clean up invitation data in the db:
  # - old unaccepted invitations are removed from the db. The interval after which invitations are discarded
  # is configurable
  # - reset the daily invitations limit for all users.
  # - reset the daily invitations count for users who have never had it reset, or who had it reset more than
  # one day ago. Users whose invitations count is zero won't be touched.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    InvitationsManager.destroy_old_invitations
    InvitationsManager.update_daily_limit
    InvitationsManager.reset_invitations_count
  end
end