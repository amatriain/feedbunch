require 'subscriptions_manager'

##
# Class with methods related to changing the read/unread state of entries.

class EntryStateManager

  ##
  # Change the read or unread state of several entries, for a given user.
  #
  # Receives as arguments:
  # - the entry to be changed state
  # - the state in which to put it. Supported values are only "read" and "unread"; this method
  # does nothing if a different value is passed
  # - the user for which the state will be set.
  # - update_older (optional): boolean to indicate whether other entries in the same feed **older** than
  # the one passed as argument are to be changed state as well.
  #
  # If the update_older optional named argument is passed as true, all entries in the same feed as the
  # passed entry which either:
  # - have an older publish date than the passed entry
  # - or have the same publish date but a smaller id
  # are considered to be older and therefore set as read or unread depending on the "state" argument.

  def self.change_entries_state(entry, state, user, update_older: false)
    if state == 'read'
      read = true
    elsif state == 'unread'
      read = false
    else
      return nil
    end

    entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
    entry_state.read = read
    entry_state.save!

    if update_older
      entries = Entry.where('feed_id=? AND (published < ? OR  (published = ? AND id < ?) )',
                            entry.feed_id, entry.published, entry.published, entry.id)
      entries.each do |e|
        entry_state = EntryState.where(user_id: user.id, entry_id: e.id).first
        entry_state.read = read
        entry_state.save!
      end
    end

    return nil
  end
end