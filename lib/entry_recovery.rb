##
# This class has methods related to recovering entries from the database

class EntryRecovery

  ##
  # Retrieve entries from the feed passed as argument, that are in the passed state for the passed user.
  #
  # Receives as arguments:
  # - id of the feed from which to retrieve entries.
  # - user for whom the read/unread state of each entry will be considered.
  # - include_read (optional): boolean that indicates whether to include both read and unread entries
  # (if true) or just unread entries (if false). By default this argument is false.
  #
  # Raises an ActiveRecord::RecordNotFound error if the user is not subscribed to the feed.
  #
  # If successful, returns an ActiveRecord::Relation with the entries.

  def self.feed_entries(feed_id, include_read=false, user)
    # ensure user is subscribed to the feed
    feed = user.feeds.find feed_id

    if include_read
      return feed.entries
    else
      return unread_feed_entries feed, user
    end
  end

  ##
  # Retrieve entries in the folder passed as argument that are marked as unread for this user.
  # In this context, "entries in the folder" means "entries from all feeds in the folder".
  #
  # Receives as arguments:
  # - the id of the folder from which to retrieve entries. The special value
  # "all" means that unread entries should be retrieved from ALL subscribed feeds.
  # - the user for which entries are unread.
  #
  # Raises an ActiveRecord::RecordNotFound error if the folder does not belong to the user.
  #
  # If successful, returns an ActiveRecord::Relation with the entries.

  def self.unread_folder_entries(folder_id, user)
    if folder_id == 'all'
      Rails.logger.info "User #{user.id} - #{user.email} is retrieving unread entries from all subscribed feeds"
      entries = Entry.joins(:entry_states).where entry_states: {read: false, user_id: user.id}
    else
      # ensure folder belongs to user
      folder = user.folders.find folder_id
      Rails.logger.info "User #{user.id} - #{user.email} is retrieving unread entries from folder #{folder.id} - #{folder.title}"
      entries = Entry.joins(:entry_states, feed: :folders).where entry_states: {read: false, user_id: user.id},
                                                                 folders: {id: folder_id}
    end

    return entries
  end

  private
  
  #
  # Retrieve entries from the feed passed as argument that are marked as unread for the user passed.
  #
  # Receives as arguments the feed from which entries are to be retrieved, and the
  # user for which entries are unread.
  #
  # Returns an ActiveRecord::Relation with the entries if successful.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def self.unread_feed_entries(feed, user)
    Rails.logger.info "User #{user.id} - #{user.email} is retrieving unread entries from feed #{feed.id} - #{feed.fetch_url}"
    entries = Entry.joins(:entry_states, :feed).where entry_states: {read: false, user_id: user.id},
                                                      feeds: {id: feed.id}
    return entries
  end

end