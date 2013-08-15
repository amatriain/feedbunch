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
# The unread_entries attribute serves as a pre-calculated count of the unread entries in the folder. This enables us
# to display this number without having to execute an expensive SQL count operation every time.

class Folder < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :title

  belongs_to :user
  validates :user_id, presence: true
  has_and_belongs_to_many :feeds, -> {uniq}, before_add: :before_add_feed, after_remove: :after_remove_feed
  has_many :entries, through: :feeds

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}
  validates :unread_entries, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :before_folder_validation

  private

  ##
  # Before validation of the folder instance:
  # - give default value to its attributes
  # - sanitize those attributes that need it

  def before_folder_validation
    default_values
    sanitize_attributes
  end

  ##
  # By default the number of unread entries is zero, if not set.

  def default_values
    self.unread_entries = 0 if self.unread_entries.blank?
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
  # Before adding a feed to a folder:
  # - ensure that the feed is only in this folder, for the current user.
  # - increment the count of unread entries in the folder.

  def before_add_feed(feed)
    single_user_folder feed
    increment_unread_count feed
  end

  ##
  # Check if the feed is already in another folder owned by the same user.
  # In this case, remove it from the old folder before adding it to the new one.

  def single_user_folder(feed)
    old_folder = feed.folders.where(user_id: self.user_id).first
    if old_folder.present?
      old_folder.feeds.delete feed
    end
  end

  ##
  # Increment the current count of unread entries in the folder, by the count of unread entries
  # in the feed being added to the folder.
  #
  # Remember that unread entries counts for feeds are relative to the user; this is, different users
  # will likely have a different number of unread entries in the same feed.

  def increment_unread_count(feed)
    count = self.user.feed_unread_count feed
    Rails.logger.debug "Feed #{feed.id} - #{feed.title} with #{count} unread entries added to folder #{self.id} - #{self.title}. Incrementing unread entries count, current: #{self.unread_entries}, incremented by #{count}"
    self.unread_entries += count
    self.save!
  end

  ##
  # After removing a feed from a folder:
  # - delete the folder if it's now empty
  # - otherwise, decrement the count of unread entries in the folder, by the count of unread entries
  # in the feed being removed from the folder
  #
  # Remember that unread entries counts for feeds are relative to the user; this is, different users
  # will likely have a different numer of unread entries in the same feed.

  def after_remove_feed(feed)
    remove_empty_folders feed
    decrement_unread_count feed if !self.destroyed?
  end

  ##
  # After removing a feed from a folder, check if there are no more feeds in the folder.
  # In this case, delete the folder from the database.

  def remove_empty_folders(feed)
    if self.feeds.blank?
      self.destroy
    end
  end

  def decrement_unread_count(feed)
    count = self.user.feed_unread_count feed
    Rails.logger.debug "Feed #{feed.id} - #{feed.title} with #{count} unread entries removed from folder #{self.id} - #{self.title}. Decrementing unread entries count, current: #{self.unread_entries}, decremented by #{count}"
    self.unread_entries -= count
    self.save!
  end
end
