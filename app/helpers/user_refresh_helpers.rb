##
# Module with functions related to refreshing feeds and folders

module UserRefreshHelpers

  ##
  # Refresh a feed; this triggers a fetch of the feed from its server.
  #
  # Receives as argument the id of the feed to refresh.
  #
  # Returns an ActiveRecord::Relation with the unread entries for the refreshed feed; this may or may
  # not contain new entries.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def refresh_feed(feed_id)
    # ensure user is subscribed to the feed
    feed = self.feeds.find feed_id

    Rails.logger.info "User #{self.id} - #{self.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    FeedClient.fetch feed.id
    entries = self.unread_feed_entries feed.id
    return entries
  end

  ##
  # Refresh a folder; this triggers a fetch of all the feeds in the folder.
  #
  # Receives as argument the id of the folder to refresh. The special value "all" means that ALL subscribed feeds
  # will be fetched, regardless of what folder they are in (and even if they are in no folder).
  #
  # Returns an ActiveRecord::Relation with the unread entries for the feeds in the folder; this may or may
  # not contain new entries.
  #
  # If the folder does not belong to the user, an ActiveRecord::RecordNotFound error is raised.

  def refresh_folder(folder_id)
    if folder_id == 'all'
      Rails.logger.info "User #{self.id} - #{self.email} is refreshing all subscribed feeds"
      feeds = self.feeds
    else
      # ensure folder belongs to the user
      folder = self.folders.find folder_id
      Rails.logger.info "User #{self.id} - #{self.email} is refreshing folder #{folder.id} - #{folder.title}"
      feeds = folder.feeds
    end

    feeds.each {|feed| FeedClient.fetch feed.id}
    entries = self.unread_folder_entries folder_id
    return entries
  end
end