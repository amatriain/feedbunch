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
    user = User.find user_id
    feed = Feed.find feed_id

    if !user.feeds.include? feed
      raise NotSubscribedError.new
    end

    SubscriptionsManager.recalculate_unread_count feed, user
  end
end