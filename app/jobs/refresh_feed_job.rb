require 'feed_updater'

##
# Background job for user-requested updates to a feed.
#
# Its perform method will be invoked from a Resque worker.

class RefreshFeedJob
  @queue = :update_feeds

  ##
  # Fetch and update entries for the passed feed.
  # Receives as argument the id of the feed to be fetched.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(user_id, feed_id)
    # TODO Change arguments to a single refresh_feed_job_status_id !!!!!

    # Check that user actually exists
    if !User.exists? user_id
      Rails.logger.warn "User #{user_id} requested refresh of feed #{feed_id}, but the user does not exist in the database."
      return
    end
    user = User.find user_id

    # Check that user is subscribed to the feed
    if !user.feeds.exists? feed_id
      Rails.logger.warn "User #{user_id} requested refresh of feed #{feed_id}, but the user is not subscribed to the feed."
      return
    end

    FeedUpdater.update_feed feed_id
  end
end