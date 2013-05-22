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
    FeedClient.fetch feed.id
    entries = user.unread_feed_entries feed.id
    return entries
  end

  ##
  # Refresh a folder; this triggers a fetch of all the feeds in the folder.
  #
  # Receives as arguments:
  # - the id of the folder to refresh. The special value "all" means that ALL subscribed feeds
  # will be fetched, regardless of what folder they are in (and even if they are in no folder).
  # - the user that requested the refresh, if any.
  #
  # Returns an ActiveRecord::Relation with the unread entries for the feeds in the folder; this may or may
  # not contain new entries.
  #
  # If the folder does not belong to the user, an ActiveRecord::RecordNotFound error is raised.

  def self.refresh_folder(folder_id, user)
    if folder_id == 'all'
      Rails.logger.info "User #{user.id} - #{user.email} is refreshing all subscribed feeds"
      feeds = user.feeds
    else
      # ensure folder belongs to the user
      folder = user.folders.find folder_id
      Rails.logger.info "User #{user.id} - #{user.email} is refreshing folder #{folder.id} - #{folder.title}"
      feeds = folder.feeds
    end

    feeds.each {|feed| FeedClient.fetch feed.id}
    entries = user.unread_folder_entries folder_id
    return entries
  end
end