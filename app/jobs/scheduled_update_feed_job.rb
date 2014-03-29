require 'subscriptions_manager'
require 'schedule_manager'
require 'feed_updater'

##
# Background job for scheduled updates to a feed.
#
# Its perform method will be invoked from a Resque worker.

class ScheduledUpdateFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(feed_id)
    FeedUpdater.update_feed feed_id
  end
end