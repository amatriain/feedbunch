##
# Entry-state model. Each instance of this class represents the state (read or unread) of a single entry for a
# single user.
#
# Each entry-state belongs to a single user, and each user can have many entry-states (one-to-many relationship).
#
# Also, each entry-state belongs to a single entry, and each entry can have many entry-states, one for each user
# subscribed to its feed (one-to-many relationship).
#
# A given entry can have at most one entry_state for a given user.
#
# The model fields are:
#
# - read: boolean. Mandatory. Indicates whether a user has read an entry or not.
# - user_id: integer. Mandatory. ID of the user who has read/unread the entry.
# - entry_id; integer. Mandatory. ID of the feed entry which is read/unread.
#
# New entries start in the unread state for all subscribed users when a feed is fetched. As a user reads entries,
# they are automatically marked as read unless he manually changes their state. By default, only unread entries
# are shown to the user in the view, unless he manually indicates he wants to also see read entries.

class EntryState < ActiveRecord::Base
  attr_accessible :read

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :entry_id}

  belongs_to :entry
  validates :entry_id, presence: true, uniqueness: {scope: :user_id}

  validates :read, inclusion: {in: [true, false]}

  after_create :increment_unread_count
  before_destroy :decrement_unread_count

  private

  ##
  # If the entry is unread, increment by 1 the cached unread entries count after creating the state.

  def increment_unread_count
    if !self.read
      UnreadEntriesCountCaching.increment_feed_count self.entry.feed.id, self.user
    end
  end

  ##
  # If the entry was unread, decrement by 1 the cached unread entries count before deleting the state.

  def decrement_unread_count
    if !self.read
      UnreadEntriesCountCaching.decrement_feed_count self.entry.feed.id, self.user
    end
  end
end
