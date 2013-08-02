##
# This class has methods related to recovering and updating the cached unread entries count
# for feeds and folders.

class UnreadEntriesCountCaching

  ##
  # Retrieve the count of unread entries in a feed for a given user. This count is not
  # calculated when this method is invoked, but rather it is retrieved from a pre-calculated
  # field in the database.
  #
  # Receives as arguments:
  # - id of the feed from which to retrieve the count
  # - user for whom the unread entries count is to be retrieved
  #
  # Returns a positive (or zero) integer with the count.

  def self.unread_feed_entries_count(feed_id, user)
    feed_subscription = user.feed_subscriptions.where(feed_id: feed_id).first
    return feed_subscription.unread_entries
  end

  ##
  # Increment the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - increment: how much to increment the count. Optional, has default value of 1.
  # - id of the feed which count will be incremented
  # - user for which the count will be incremented

  def self.increment_feed_count(increment=1, feed_id, user)
    feed_subscription = user.feed_subscriptions.where(feed_id: feed_id).first
    feed_subscription.unread_entries += increment
    feed_subscription.save!
  end

  ##
  # Decrement the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - decrement: how much to decrement the count. Optional, has default value of 1.
  # - id of the feed which count will be decremented
  # - user for which the count will be decremented

  def self.decrement_feed_count(decrement=1, feed_id, user)
    feed_subscription = user.feed_subscriptions.where(feed_id: feed_id).first
    feed_subscription.unread_entries -= decrement
    feed_subscription.save!
  end
end