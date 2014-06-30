require 'signups_manager'

##
# Background job to clean up data related to signups.
#
# The perform method of this class will be invoked from a Resque worker.

class CleanupSignupsJob
  @queue = :maintenance

  ##
  # Clean up outdated signup data in the db:
  # - old unconfirmed signups are removed from the db. The interval after which invitations are discarded
  # is configurable
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform
    SignupsManager.destroy_old_signups
  end
end