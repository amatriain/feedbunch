##
# Background job to import an OPML data file with subscriptions data for a user.
# It also enqueues updates of any new feeds created (existing feeds are assumed
# to have been updated in the last hour and so don't need an update right now).
#
# Its perform method will be invoked from a Resque worker.

class ImportSubscriptionsJob
  @queue = :update_feeds

  ##
  # Import an OPML file with subscriptions for a user, and then deletes it.
  #
  # Receives as arguments:
  # - the name of the file
  # - the id of the user who is importing the file
  #
  # The file must be saved in the $RAILS_ROOT/uploads folder.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(filename, user_id)

  end
end