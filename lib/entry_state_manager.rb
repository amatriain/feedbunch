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
  # - update_older (optional): boolean to indicate whether other entries **older** than
  # the one passed as argument are to be changed state as well.
  # - folder (optional): this argument only matters if the "update_older" argument is set to true.
  # If "update_older" is set to true but nothing is passed in "folder", this method will update older
  # entries **in the same feed as the passed entry**. If "update_older" is set to true and a folder is passed
  # in this argument, this method will update older entries **in the same folder as the passed entry** (which
  # could mean updating entries in several feeds).
  #
  # If the update_older optional named argument is passed as true, entries in the same feed/folder as the
  # passed entry which either:
  # - have an older publish date than the passed entry
  # - or have the same publish date but a smaller id
  # are considered to be older and therefore set as read or unread depending on the "state" argument.

  def self.change_entries_state(entry, state, user, update_older: false, folder: nil)
    if state == 'read'
      read = true
    elsif state == 'unread'
      read = false
    else
      return nil
    end

    if update_older
      if folder.present?
      else
        change_feed_entries_state entry, read, user
      end
    else
      entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
      entry_state.read = read
      entry_state.save!
    end

    return nil
  end

  private

  ##
  # Change the read/unread state for all entries in a feed older than the passed entry.
  #
  # Receives as arguments:
  # - entry: this entry, and all entries in the same feed older than this one, will be marked as read.
  # - read: boolean argument indicating if entries will be marked as read (true) or unread (false).
  # - user: user for whom the read/unread state will be set.

  def self.change_feed_entries_state(entry, read, user)
    entries = Entry.where('feed_id=? AND (published < ? OR  (published = ? AND id <= ?) )',
                          entry.feed_id, entry.published, entry.published, entry.id)
    entries.each do |e|
      entry_state = EntryState.where(user_id: user.id, entry_id: e.id).first
      entry_state.read = read
      entry_state.save!
    end
  end
end