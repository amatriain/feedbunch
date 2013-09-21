require 'subscriptions_manager'

##
# Class with methods related to changing the read/unread state of entries.

class EntryStateManager

  ##
  # Change the read or unread state of several entries, for a given user.
  #
  # Receives as arguments:
  # - an array with the entries to be changed state
  # - the state in which to put them. Supported values are only "read" and "unread"; this method
  # does nothing if a different value is passed
  # - the user for which the state will be set.

  def self.change_entries_state(entries, state, user)
    entries.each do |entry|
      entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
      if state == 'read'
        entry_state.read = true
      elsif state == 'unread'
        entry_state.read = false
      end
      entry_state.save!
    end

    return nil
  end
end