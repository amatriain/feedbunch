##
# Folder model. Each instance of this class represents a single folder to which a user can add feeds.
#
# Each folder belongs to a single user, and each user can have many folders (one-to-many relationship).
#
# Each folder can be associated with many feeds, and each feed can be associated with many folders as long as they
# belong to different users (many-to-many relationship, through the feed_folders table). However a feed can be
# associated with at most one folder belonging to a single user.
#
# A relationship is also established between Folder and Entry models, through the Feed model. This enables us to retrieve
# all entries for all feeds inside a folder.
#
# The title field is mandatory. As it is introduced by the user, it is sanitized before saving in the database.
#
# A given user cannot have two folders with the same title. Folders with the same title are allowed as long as they
# belong to different users.
#
# The subscriptions_updated_at attribute indicates the date/time at which a feed in the folder was last changed.
# Events that update this attribute are:
#   - unsubscribing from a feed in the folder
#   - changing the unread entries count for a feed in the folder
#   - changing the title of a feed in the folder
#   - changing the URL of a feed in the folder
#   - moving a feed into or out of the folder

class Folder < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  # Class constants for special "no folder" and "all folders" cases
  NO_FOLDER = 'none'
  ALL_FOLDERS = 'all'

  belongs_to :user
  validates :user_id, presence: true
  has_and_belongs_to_many :feeds, -> {uniq},
                          before_add: :before_add_feed,
                          after_add: :after_add_feed,
                          after_remove: :after_remove_feed
  has_many :entries, through: :feeds

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}

  before_validation :before_folder_validation

  ##
  # Update the subscriptions_updated_at attribute with the current date/time

  def touch_subscriptions
    now = Time.zone.now
    Rails.logger.info "Updating subscriptions_updated_at attribute of folder #{id} - #{title} with current date/time: #{now}"
    update subscriptions_updated_at: now
  end

  private

  ##
  # Before validation of the folder instance:
  # - sanitize those attributes that need it

  def before_folder_validation
    sanitize_attributes
    default_values
  end

  ##
  # Sanitize the title of the folder.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_attributes
    self.title = sanitize self.title
  end

  ##
  # Give the following default values to the folder, in case no value or an invalid value is set:
  # - subscriptions_updated_at: the current date/time

  def default_values
    if subscriptions_updated_at == nil
      Rails.logger.info "Folder #{id} - #{title} has unsupported subscriptions_updated_at value, using current datetime by default"
      self.subscriptions_updated_at = Time.zone.now
    end
  end

  ##
  # Before adding a feed to a folder remove the feed from its old folder, if any.

  def before_add_feed(feed)
    feed.remove_from_folder self.user
  end

  ##
  # After adding a feed to a folder, update the date/time of change of subscriptions.

  def after_add_feed(feed)
    touch_subscription feed
  end

  ##
  # After removing a feed from a folder:
  # - touch the FeedSubscription instance for the passed feed and the user that owns this folder,
  # updating its updated_at attribute.
  # - delete the folder if it's now empty

  def after_remove_feed(feed)
    touch_subscription feed
    remove_empty_folders feed
    touch_subscription feed
  end

  ##
  # Update the date/time of change of subscriptions:
  # - update the subscriptions_updated_at attribute of the associated user with the current date/time
  # - touch the FeedSubscription instance for the passed feed and the user that owns this folder,
  # updating its updated_at attribute.
  #
  # This will invalidate HTTP caches, forcing clients to download fresh data.

  def touch_subscription(feed)
    subscription = FeedSubscription.where(feed_id: feed.id, user_id: user_id).first
    Rails.logger.info "touching feed subscription for feed #{feed.id} - #{feed.title}, user #{user_id} - #{user.email}"
    subscription.touch
    user.touch_subscriptions
  end

  ##
  # After removing a feed from a folder, check if there are no more feeds in the folder.
  # In this case, delete the folder from the database.

  def remove_empty_folders(feed)
    if self.feeds.blank?
      self.destroy
    end
  end
end
