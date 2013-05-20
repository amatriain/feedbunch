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
  attr_accessible :read, :user_id, :entry_id, as: :admin

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :entry_id}
  belongs_to :entry
  validates :entry_id, presence: true, uniqueness: {scope: :user_id}

  validates :read, inclusion: {in: [true, false]}
end
