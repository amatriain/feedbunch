##
# This class has methods to refresh feeds, either one by one or all feeds in a folder at once.

class FeedRefresh

  ##
  # Refresh a feed; this triggers a fetch of the feed from its server.
  #
  # Receives as argument the id of the feed to refresh and the user that requested the refresh, if any..
  #
  # Returns an ActiveRecord::Relation with the unread entries for the refreshed feed; this may or may
  # not contain new entries.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def self.refresh_feed(feed_id, user)
    # ensure user is subscribed to the feed
    feed = user.feeds.find feed_id

    Rails.logger.info "User #{user.id} - #{user.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    FeedClient.fetch feed.id, false
    entries = user.feed_entries feed.id
    return entries
  end
end