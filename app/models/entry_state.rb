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
# - published: datetime when the entry was published. This has the same value as the "published" attribute of the
# corresponding Entry instance, it is copied to this model to denormalize the database and get faster queries.
# - entry_created_at: datetime when the entry was crated. This has the same value as the "created_at" attribute of
# the corresponding Entry instance, it is copied to this model to denormalize the database and get faster queries.
#
# New entries start in the unread state for all subscribed users when a feed is fetched. As a user reads entries,
# they are automatically marked as read unless he manually changes their state. By default, only unread entries
# are shown to the user in the view, unless he manually indicates he wants to also see read entries.

class EntryState < ApplicationRecord

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :entry_id}

  belongs_to :entry
  validates :entry_id, presence: true, uniqueness: {scope: :user_id}

  validates :published, presence: true
  validates :entry_created_at, presence: true

  validates :read, inclusion: {in: [true, false]}

  before_validation :fixed_values

  private

  ##
  # The published and entry_created_at attributes always have the same value as the corresponding attributes in the
  # associated Entry instance.
  # This is just a db denormalization to speed up queries.
  # No other value can be set, every time the EntryState instance is saved these attributes are reset to their
  # default value.

  def fixed_values
    if self.entry.present?
      self.published = self.entry.published
      self.entry_created_at = self.entry.created_at
    end
  end
end
