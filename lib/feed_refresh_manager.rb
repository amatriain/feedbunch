##
# This class has methods to refresh feeds.

class FeedRefreshManager

  ##
  # Refresh a feed; this triggers a fetch of the feed from its server.
  #
  # Receives as argument the feed to refresh and the user that requested the refresh, if any.
  #
  # Returns nil.

  def self.refresh(feed, user)
    Rails.logger.info "User #{user.id} - #{user.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    if !user.feeds.include? feed
      Rails.logger.warn "User #{user.id} - #{user.email} requested refresh of feed #{feed.id} - #{feed.fetch_url} to which he's not subscribed"
      raise NotSubscribedError.new
    end
    FeedClient.fetch feed, false
    return nil
  end
end