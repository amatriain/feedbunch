require 'invitations_manager'

##
# Background job to clean up data related to invitations.
#
# The perform method of this class will be invoked from a Resque worker.

class CleanupInvitationsJob
  @queue = :maintenance

  ##
  # Clean up invitation data in the db:
  # - old unaccepted invitations are removed from the db. The interval after which invitations are discarded
  # is configurable
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform
    InvitationsManager.destroy_old_invitations
  end
end