##
# Class with methods related to changing the read/unread state of entries.

class EntryStateChange

  ##
  # Change the read or unread state of an entry, for a given user.
  #
  # Returns the feed instance to which the entry belongs.

  def self.change_entry_state(entry_id, state, user)
    entry = user.entries.find entry_id
    entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
    if state == 'read'
      entry_state.read = true
    elsif state == 'unread'
      entry_state.read = false
    end
    entry_state.save!
    return entry_state.entry.feed
  end
end