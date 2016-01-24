require 'subscriptions_manager'

##
# Class with methods related to changing the read/unread state of entries.

class EntryStateManager

  ##
  # Change the read or unread state of an entry, for a given user.
  #
  # Receives as arguments:
  # - the entry to be changed state
  # - the state in which to put it. Supported values are only "read" and "unread"; this method
  # does nothing if a different value is passed
  # - the user for which the state will be set.
  # - whole_feed (optional): boolean to indicate whether other entries in the same feed **older** than
  # the one passed as argument are to be changed state as well.
  # - whole_folder (optional): boolean to indicate whether other entries in the same folder **older** than
  # the one passed as argument are to be changed state as well.
  # - all_entries (optional): boolean to indicate whether **ALL** entries from all subscribed feeds **older**
  # than the one passed as argument are to be changed state as well.
  #
  # If the update_feed or update_folder optional named arguments are passed as true,
  # entries in the same feed/folder as the passed entry which either:
  # - have an older publish date than the passed entry
  # - or have the same publish date but a smaller id
  # are considered to be older and therefore set as read or unread depending on the "state" argument.

  def self.change_entries_state(entry, state, user, whole_feed: false, whole_folder: false, all_entries: false)
    if state == 'read'
      read = true
    elsif state == 'unread'
      read = false
    else
      return nil
    end

    if !whole_feed && !whole_folder && !all_entries
      # Update a single entry
      entry_state = EntryState.find_by user_id: user.id, entry_id: entry.id
      entry_state.update read: read
      # Update unread entries count for the feed
      if read
        SubscriptionsManager.feed_decrement_count entry.feed, user
      else
        SubscriptionsManager.feed_increment_count entry.feed, user
      end
    else
      change_feed_entries_state entry, read, user if whole_feed
      change_folder_entries_state entry, read, user if whole_folder
      change_all_entries_state entry, read, user if all_entries
    end

    return nil
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Change the read/unread state for all entries in a feed older than the passed entry.
  #
  # Receives as arguments:
  # - entry: this entry, and all entries in the same feed older than this one, will be marked as read.
  # - read: boolean argument indicating if entries will be marked as read (true) or unread (false).
  # - user: user for whom the read/unread state will be set.

  def self.change_feed_entries_state(entry, read, user)
    # Join with entry_states to select only those entries that don't already have the desired state.
    EntryState.joins(:entry).
      where(entry_states: {user_id: user.id, read: !read}).
      where('entries.feed_id=? AND (entries.published<? OR (entries.published=? AND entries.id<=?))',
            entry.feed_id, entry.published, entry.published, entry.id).
      update_all read: read

    # Update unread entries count for the feed
    SubscriptionsManager.recalculate_unread_count entry.feed, user
  end
  private_class_method :change_feed_entries_state

  ##
  # Change the read/unread state for all entries in a folder older than the passed entry.
  #
  # Receives as arguments:
  # - entry: this entry, and all entries in the same feed older than this one, will be marked as read.
  # - read: boolean argument indicating if entries will be marked as read (true) or unread (false).
  # - user: user for whom the read/unread state will be set.

  def self.change_folder_entries_state(entry, read, user)
    folder = entry.feed.user_folder user
    # Join with entry_states to select only those entries that don't already have the desired state.
    EntryState.joins(entry: {feed: :folders}).
      where(entry_states: {user_id: user.id, read: !read}, folders: {id: folder.id}).
      where('entries.published<? OR (entries.published=? AND entries.id<=?)',
            entry.published, entry.published, entry.id).
      update_all read: read

    # Update unread entries count for the feeds
    folder.feeds.find_each do |f|
      SubscriptionsManager.recalculate_unread_count f, user
    end
  end
  private_class_method :change_folder_entries_state

  ##
  # Change the read/unread state for all entries in all subscribed feeds.
  #
  # Receives as arguments:
  # - entry: this entry, and all entries in subscribed feeds older than this one, will be marked as read.
  # - read: boolean argument indicating if entries will be marked as read (true) or unread (false).
  # - user: user for whom the read/unread state will be set.

  def self.change_all_entries_state(entry, read, user)
    # Join with entry_states to select only those entries that don't already have the desired state.
    EntryState.joins(:entry).where(entry_states: {user_id: user.id, read: !read}).
      where('entries.published<? OR (entries.published=? AND entries.id<=?)',
            entry.published, entry.published, entry.id).
      update_all read: read

    # Update unread entries count for the feeds
    user.feeds.find_each do |f|
      SubscriptionsManager.recalculate_unread_count f, user
    end
  end
  private_class_method :change_all_entries_state
end
