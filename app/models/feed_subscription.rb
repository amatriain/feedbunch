##
# Feed subscription model. Each instance of this class represents a subscription from a single user
# to a single feed.
#
# Each subscription belongs to a single user, and each user can have many subscriptions (one-to-may relationship).
#
# Also, each subscription belongs to a single feed, and each feed can be subscribed to many times (one-to-many relationship).
#
# A given feed can be subscribed at most once by a given user.
#
# The model fields are:
#
# - user_id: integer. Mandatory. ID of the user who is subscribed to the feed.
# - feed_id: integer. Mandatory. ID of the feed to which the user is subscribed
# - unread_entries: integer. Mandatory. Number of entries in the feed the user has not read yet.
#
# When a user subscribes to a feed, initially all entries are unread, contributing to the unread_entries attribute.
# As entries change state for the user, the attribute decreases (when entries become read) or increases (when entries
# become unread).

class FeedSubscription < ActiveRecord::Base

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :feed_id}

  belongs_to :feed
  validates :feed_id, presence: true, uniqueness: {scope: :user_id}

  validates :unread_entries, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :default_values

  private

  ##
  # By default the number of unread entries is zero, if not set.

  def default_values
    self.unread_entries = 0 if self.unread_entries.blank?
  end
end