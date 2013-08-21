##
# This class has methods to refresh feeds, either one by one or all feeds in a folder at once.

class FeedRefresh

  ##
  # Refresh a feed; this triggers a fetch of the feed from its server.
  #
  # Receives as argument the feed to refresh and the user that requested the refresh, if any..
  #
  # Returns an ActiveRecord::Relation with the unread entries for the refreshed feed; this may or may
  # not contain new entries.

  def self.refresh_feed(feed, user)

    Rails.logger.info "User #{user.id} - #{user.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    FeedClient.fetch feed.id, false
    entries = user.feed_entries feed
    return entries
  end
end