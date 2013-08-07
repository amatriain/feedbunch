##
# This class has methods related to recovering and updating the cached unread entries count
# for feeds and folders.

class SubscriptionsManager

  ##
  # Add a new subscription of a user to a feed. The cached count of unread entries will be
  # initialized to the current number of entries in the feed, thanks to various model callbacks.
  #
  # Receives as arguments the suscribing user and the feed to which he's to be subscribed.
  #
  # If the user is already subscribed to the feed, an AlreadySubscribedError is raised.

  def self.add_subscription(feed, user)
    if user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to subscribed to feed #{feed.id} - #{feed.fetch_url} to which he is already subscribed"
      raise AlreadySubscribedError.new
    end

    Rails.logger.info "subscribing user #{user.id} - #{user.email} to feed #{feed.id} - #{feed.fetch_url}"
    feed_subscription = FeedSubscription.new
    feed_subscription.feed = feed
    user.feed_subscriptions << feed_subscription
  end

  ##
  # Unsubscribes a user from a feed.
  #
  # Receives as argument the feed to unsubscribe, and the user who is unsubscribing.
  #
  # Returns a Folder instance with the data of the folder in which the feed was previously, or nil
  # if it wasn't in any folder. This object may have already  been deleted from the database,
  # if there were no more feeds in it.
  #
  # If the user is not subscribed to the feed, a NotSubscribedError is raised.

  def self.remove_subscription(feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to unsubscribe from feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end

    feed_subscription = FeedSubscription.where(feed_id: feed.id, user_id: user.id).first
    folder = feed.user_folder user

    Rails.logger.info "unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.fetch_url}"
    user.feed_subscriptions.delete feed_subscription

    return folder
  end

  ##
  # Retrieve the count of unread entries in a feed for a given user. This count is not
  # calculated when this method is invoked, but rather it is retrieved from a pre-calculated
  # field in the database.
  #
  # Receives as arguments:
  # - feed from which to retrieve the count
  # - user for whom the unread entries count is to be retrieved
  #
  # Returns a positive (or zero) integer with the count.
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_unread_count(feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to get unread entries count from feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    return feed_subscription.unread_entries
  end

  ##
  # Increment the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - increment: how much to increment the count. Optional, has default value of 1.
  # - feed which count will be incremented
  # - user for which the count will be incremented
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_increment_count(increment=1, feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to increment unread entries count for feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    Rails.logger.debug "Incrementing unread entries count for user #{user.id} - #{user.email}, feed #{feed.id} - #{feed.fetch_url}. Current: #{feed_subscription.unread_entries}, incremented by #{increment}"
    feed_subscription.unread_entries += increment
    feed_subscription.save!
  end

  ##
  # Decrement the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - decrement: how much to decrement the count. Optional, has default value of 1.
  # - feed which count will be decremented
  # - user for which the count will be decremented
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_decrement_count(decrement=1, feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to decrement unread entries count for feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    Rails.logger.debug "Decrementing unread entries count for user #{user.id} - #{user.email}, feed #{feed.id} - #{feed.fetch_url}. Current: #{feed_subscription.unread_entries}, decremented by #{decrement}"
    feed_subscription.unread_entries -= decrement
    feed_subscription.save!
  end

  private

  ##
  # Find out if a user is subscribed to a feed.
  #
  # Receives as arguments the feed and the user to check.
  #
  # Returns true if the user is subscribed to the feed, false otherwise.

  def self.user_subscribed?(feed, user)
    if FeedSubscription.exists? feed_id: feed.id, user_id: user.id
      return true
    else
      return false
    end
  end
end