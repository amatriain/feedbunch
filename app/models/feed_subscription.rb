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

class FeedSubscription < ApplicationRecord

  belongs_to :user
  validates :user_id, presence: true, uniqueness: {scope: :feed_id}

  belongs_to :feed
  validates :feed_id, presence: true, uniqueness: {scope: :user_id}

  validates :unread_entries, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :default_values
  after_create :after_create
  before_destroy :before_destroy, prepend: true
  after_save :after_save

  ##
  # Update the date in which subscriptions have been changed:
  # - touch this FeedSubscription instance, updating its updated_at attribute
  # - update the subscriptions_updated_at attribute of the associated user to the current date/time
  # - update the subscriptions_updated_at attribute of the folder which contains the feed, if any, to the
  # current date/time

  def touch_subscriptions
    Rails.logger.info "Touching subscription of user #{user_id} to feed #{feed_id}"
    self.touch if !destroyed?
    if user.present?
      user.update subscriptions_updated_at: Time.zone.now
      folder = feed.user_folder user
      folder.update subscriptions_updated_at: Time.zone.now if folder.present?
    end
  end

  private

  ##
  # By default the number of unread entries is zero, if not set.

  def default_values
    self.unread_entries = 0 if self.unread_entries.blank? || self.unread_entries < 0
  end

  ##
  # After creating a new subscription:
  # - set the initial unread entries count
  # - update the date/time of change of subscriptions
  # - update the date/time of change of user data

  def after_create
    initial_unread_entries
    touch_subscriptions
    touch_user_data
  end

  ##
  # After destroying a subscription:
  # - update the date/time of change of subscriptions
  # - update the date/time of change of user data

  def before_destroy
    touch_subscriptions
    touch_user_data
  end

  ##
  # The initial value of the unread entries count is the number of entries

  def initial_unread_entries
    update unread_entries: feed.entries.count
  end

  ##
  # If the unread entries count has changed, touch subscriptions

  def after_save
    touch_subscriptions if saved_change_to_unread_entries?
  end

  ##
  # Update the user_data_updated_at attribute of the associated user with the current datetime.

  def touch_user_data
    user.update user_data_updated_at: Time.zone.now if user.present?
  end
end