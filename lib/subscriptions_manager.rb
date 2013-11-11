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
    check_user_unsubscribed feed, user

    Rails.logger.info "subscribing user #{user.id} - #{user.email} to feed #{feed.id} - #{feed.fetch_url}"
    feed_subscription = FeedSubscription.new feed_id: feed.id
    user.feed_subscriptions << feed_subscription
    self.recalculate_unread_count feed, user

    return nil
  end

  ##
  # Unsubscribes a user from a feed.
  #
  # Receives as argument the feed to unsubscribe, and the user who is unsubscribing.
  #
  # If the user is not subscribed to the feed, a NotSubscribedError is raised.

  def self.remove_subscription(feed, user)
    check_user_subscribed feed, user

    feed_subscription = FeedSubscription.where(feed_id: feed.id, user_id: user.id).first
    Rails.logger.info "unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.fetch_url}"
    user.feed_subscriptions.delete feed_subscription

    return nil
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
    check_user_subscribed feed, user

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    return feed_subscription.unread_entries
  end

  ##
  # Increment the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - feed which count will be incremented
  # - user for which the count will be incremented
  # - increment: how much to increment the count. Optional, has default value of 1.
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_increment_count(feed, user, increment=1)
    check_user_subscribed feed, user

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    Rails.logger.debug "Incrementing unread entries count for user #{user.id} - #{user.email}, feed #{feed.id} - #{feed.fetch_url}. Current: #{feed_subscription.unread_entries}, incremented by #{increment}"
    feed_subscription.unread_entries += increment
    feed_subscription.save!

    return nil
  end

  ##
  # Decrement the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - feed which count will be decremented
  # - user for which the count will be decremented
  # - decrement: how much to decrement the count. Optional, has default value of 1.
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_decrement_count(feed, user, decrement=1)
    self.feed_increment_count feed, user, -decrement
  end

  ##
  # Recalculate the count of unread entries in a feed for a given user.
  #
  # This method counts the unread entries in the feed and updates the unread_entries field
  # accordingly. It can be used to ensure the unread_entries field is correct.
  #
  # Receives as arguments:
  # - feed: feed for which the count will be recalculated.
  # - user: user for whom the count will be recalculated.
  #
  # Returns the recalculated count.
  #
  # This method writes in the database only if necessary (i.e. the currently saved unread_entries does
  # not match the calculated count). This avoids unnecessary database writes, which are expensive
  # operations.

  def self.recalculate_unread_count(feed, user)
    Rails.logger.debug "Recalculating unread entries count for feed #{feed.id} - #{feed.title}, user #{user.id} - #{user.email}"
    count = EntryState.joins(entry: :feed).where(read: false, user: user, feeds: {id: feed.id}).count
    if user.feed_unread_count(feed) != count
      Rails.logger.debug "Unread entries count calculated: #{count}, current value #{user.feed_unread_count(feed)}. Updating DB record."
      feed_subscription = FeedSubscription.where(user_id: user.id, feed_id: feed.id).first
      feed_subscription.update unread_entries: count
    else
      Rails.logger.debug "Unread entries count calculated: #{count}, current value is correct. No need to update DB record."
    end

    return count
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

  ##
  # Check that a user is subscribed to a feed.
  #
  # Receives as arguments the feed and user to check.
  #
  # If the user is not subscribed to the feed a NotSubscribedError is raised.
  # Otherwise nil is returned.

  def self.check_user_subscribed (feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to change unread entries count for feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end
    return nil
  end


  ##
  # Check that a user is not subscribed to a feed.
  #
  # Receives as arguments the feed and user to check.
  #
  # If the user is subscribed to the feed a NotSubscribedError is raised.
  # Otherwise nil is returned.

  def self.check_user_unsubscribed (feed, user)
    if user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to subscribe to feed #{feed.id} - #{feed.fetch_url} to which he is already subscribed"
      raise AlreadySubscribedError.new
    end
    return nil
  end
end