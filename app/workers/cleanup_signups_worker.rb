require 'signups_manager'

##
# Background job to clean up data related to signups.
#
# This is a Sidekiq worker

class CleanupSignupsWorker
  include Sidekiq::Worker

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

  ##
  # Clean up outdated signup data in the db:
  # - reminder emails are sent for unconfirmed users
  # - old unconfirmed registrations are removed from the db. The interval after which unconfirmed registrations are discarded
  # is configurable
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform
    SignupsManager.send_confirmation_reminders
    SignupsManager.destroy_old_signups
  end
end