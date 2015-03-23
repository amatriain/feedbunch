require 'subscriptions_manager'

##
# Background job to update the unread entries count of a feed
#
# This is a Sidekiq worker

class UpdateFeedUnreadCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :maintenance

  ##
  # Update the unread entries count for a feed, for a single user.
  # Receives as argument the id of the feed to update and the id of the user to update it for.
  #
  # If the feed or user does not exist, do nothing.
  # If the user is not subscribed to the feed, do nothing.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(feed_id, user_id)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.warn "Trying to update unread entries for non-existing user @#{user_id}, aborting job"
      return
    end
    user = User.find user_id

    # Check that feed actually exists
    if !Feed.exists? feed_id
      Rails.logger.warn "Trying to update unread entries for non-existing feed #{feed_id}, aborting job"
      return
    end
    feed = Feed.find feed_id

    if !user.feeds.include? feed
      Rails.logger.warn "Trying to update unread entries for feed #{feed_id} - #{feed.fetch_url}, user #{user.id} - #{user.email} but user is not subscribed to feed, aborting job"
      return
    end

    SubscriptionsManager.recalculate_unread_count feed, user
  end
end