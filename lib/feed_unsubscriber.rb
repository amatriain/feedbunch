##
# This class has methods to unsubscribe a user from a feed.

class FeedUnsubscriber

  ##
  # Unsubscribes the user from a feed.
  #
  # Receives as argument the id of the feed to unsubscribe, and the user which is unsubscribing.
  #
  # If the user is not subscribed to the feed, an ActiveRecord::RecordNotFound error is raised.
  #
  # If there are no more users subscribed to the feed, it is deleted from the database. This triggers
  # a deletion of all its entries.
  #
  # If the user had associated the feed with a folder, and after unsubscribing there are no more feeds
  # in the folder, that folder is deleted.
  #
  # Returns a Folder instance with the data of the folder in which the feed was previously, or nil
  # if it wasn't in any folder. This object may have already  been deleted from the database,
  # if there were no more feeds in it.

  def self.unsubscribe(feed_id, user)
    feed = user.feeds.find feed_id
    folder = feed.user_folder user

    Rails.logger.info "unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.fetch_url}"
    user.feeds.delete feed

    return folder
  end
end