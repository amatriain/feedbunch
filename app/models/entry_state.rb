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

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :entry_id}

  belongs_to :entry
  validates :entry_id, presence: true, uniqueness: {scope: :user_id}

  validates :read, inclusion: {in: [true, false]}

  after_create :entry_state_created
  before_destroy :entry_state_destroyed
  after_update :entry_state_updated

  private

  ##
  # If the entry is unread, increment by 1 the cached unread entries count after creating the state.

  def entry_state_created
    if !self.read
      increment_count
    end
  end

  ##
  # If the entry was unread, decrement by 1 the cached unread entries count before deleting the state.

  def entry_state_destroyed
    if !self.read
      decrement_count
    end
  end

  ##
  # If the state has been changed from read to unread, increment by 1 the cached unread entries count.
  # If it has been changed from unread to read, decrement it by 1.

  def entry_state_updated
    if self.read_changed?
      if self.read
        decrement_count
      else
        increment_count
      end
    end
  end

  ##
  # Increment by 1 all the unread entries counts (in feed, user and folder)

  def increment_count
    # Increment the feed unread entries count
    feed = self.entry.feed
    SubscriptionsManager.feed_increment_count feed, self.user

    # Increment the user unread entries count
    user.unread_entries += 1
    user.save!

    # Increment the folder unread entries count, if the feed is in a folder
    folder = feed.user_folder self.user
    if folder.present?
      Rails.logger.debug "Unread entry #{self.entry.id} - #{self.entry.guid} created. Incrementing unread entries count for user #{self.user.id} - #{self.user.email}, folder #{folder.id} - #{folder.title}. Current: #{folder.unread_entries}, incremented by 1"
      folder.unread_entries += 1
      folder.save!
    end
  end

  ##
  # Decrement by 1 all the unread entries counts (in feed, user and folder)

  def decrement_count
    # Decrement the feed unread entries count
    feed = self.entry.feed
    SubscriptionsManager.feed_decrement_count feed, self.user

    # Decrement the user unread entries count
    user.unread_entries -= 1
    user.save!

    # Decrement the folder unread entries count, if the feed is in a folder
    folder = feed.user_folder self.user
    if folder.present?
      Rails.logger.debug "Unread entry #{self.entry.id} - #{self.entry.guid} destroyed. Decrementing unread entries count for user #{self.user.id} - #{self.user.email}, folder #{folder.id} - #{folder.title}. Current: #{folder.unread_entries}, decremented by 1"
      folder.unread_entries -= 1
      folder.save!
    end
  end
end
