require 'sanitize'

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
# The subscriptions_updated_at attribute is the date/time at which a feed in the folder was last changed.
# Events that update this attribute are:
#   - unsubscribing from a feed in the folder
#   - changing the unread entries count for a feed in the folder
#   - changing the title of a feed in the folder
#   - changing the URL of a feed in the folder
#   - moving a feed into or out of the folder

class Folder < ActiveRecord::Base

  # Class constants for special "no folder" and "all folders" cases
  NO_FOLDER = 'none'
  ALL_FOLDERS = 'all'

  belongs_to :user
  validates :user_id, presence: true
  has_and_belongs_to_many :feeds, -> {uniq},
                          before_add: :before_add_feed,
                          after_add: :touch_subscription,
                          before_remove: :touch_subscription,
                          after_remove: :remove_empty_folders
  has_many :entries, through: :feeds

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}

  before_validation :before_folder_validation
  after_create :touch_folders
  after_destroy :touch_folders

  private

  ##
  # Before validation of the folder instance:
  # - sanitize those attributes that need it

  def before_folder_validation
    sanitize_attributes
    default_values
  end

  ##
  # Update the folders_updated_at attribute of the User who owns this folder to the current date and time.

  def touch_folders
    user.update folders_updated_at: Time.zone.now
  end

  ##
  # Sanitize the title of the folder.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_attributes
    config = Sanitize::Config.merge Sanitize::Config::RESTRICTED,
                                    remove_contents: true
    self.title = Sanitize.fragment self.title, config
  end

  ##
  # Give the following default values to the folder, in case no value or an invalid value is set:
  # - subscriptions_updated_at: current date/time

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
  # Update the date/time of change of subscriptions.
  #
  # This will invalidate HTTP caches, forcing clients to download fresh data.

  def touch_subscription(feed)
    subscription = FeedSubscription.find_by feed_id: feed.id, user_id: user_id
    Rails.logger.info "touching feed subscription for feed #{feed.id} - #{feed.title}, user #{user_id} - #{user.email}"
    subscription.touch_subscriptions if subscription.present?
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
