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

class Folder < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :title

  belongs_to :user
  validates :user_id, presence: true
  has_and_belongs_to_many :feeds, uniq: true, before_add: :single_user_folder
  has_many :entries, through: :feeds

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}

  before_validation :sanitize_fields

  ##
  # Add a feed to a folder. This is a class method.
  #
  # Receives as arguments the id of the feed and the id of the folder to which it's going to be associated.
  # If the feed is already associated fo another folder that belongs to the same user (folders belong to a single
  # user), it removes the feed from the old folder before associating it with the new one. This ensures that, from
  # a given user's point of view, feeds belong to a single folder.
  #
  # If the feed is already associated with the folder, an AlreadyInFolderError is raised.
  #
  # Returns the updated folder.

  def self.add_feed(folder_id, feed_id)
    folder = Folder.find folder_id
    feed = Feed.find feed_id

    # Check if feed is already associated with folder
    if folder.feeds.include? feed
      Rails.logger.warn "Feed #{feed.id} - #{feed.fetch_url} is already associated with folder #{folder.id} - #{folder.title}, nothing to do"
      raise AlreadyInFolderError.new
    end

    # Check if feed is already in another folder from the same user
    old_folder = feed.folders.where(user_id: folder.user_id).first
    if old_folder.present?
      Rails.logger.info "Feed #{feed.id} - #{feed.fetch_url} is already in folder #{old_folder} - #{old_folder.title} from user #{folder.user_id}, removing it before associating with new folder"
      feed.folders.delete old_folder
    end
    folder.feeds << feed
    return folder
  end

  ##
  # Remove a feed from a folder. This is a class method.
  #
  # Receives as arguments the id of the feed and the id of the folder from which it's going to be removed.
  #
  # If after removing the feed there are no more feeds inside the folder, the folder is completely deleted.
  #
  # If the feed is not in the passed folder a NotInFolderError is raised.
  #
  # Returns true if there are more feeds in the folder after removing this one, false otherwise. This means that
  # if the method returns true, the folder still exists; if it returns false, this means the folder
  # has been removed from the database.

  def self.remove_feed(folder_id, feed_id)
    folder = Folder.find folder_id
    feed = Feed.find feed_id

    if !folder.feeds.include? feed
      Rails.logger.warn "Tried to remove feed #{feed.id} - #{feed.fetch_url} from folder #{folder.id} - #{folder.title}, but feed was not in that folder"
      raise NotInFolderError.new
    end

    Rails.logger.info "Removing feed #{feed.id} - #{feed.fetch_url} from folder #{folder.id} - #{folder.title}"
    folder.feeds.delete feed

    if folder.feeds.blank?
      Rails.logger.info "Folder folder #{folder.id} - #{folder.title} has no more feeds, destroying it"
      folder.destroy
      return false
    else
      Rails.logger.info "Folder folder #{folder.id} - #{folder.title} has more feeds, it will not be destroyed"
      return true
    end
  end

  ##
  # Create a new folder and add it to the list of folders that belong to a user.
  #
  # Receives as arguments the title of the new folder and the id of the user to which it will belong.
  #
  # If the user already has a folder with the same title, raises a FolderAlreadyExistsError.
  #
  # If successful, returns the new folder instance.

  def self.create_user_folder(folder_title, user_id)
    user = User.find user_id

    if user.folders.where(title: folder_title).present?
      Rails.logger.info "User #{user.id} - #{user.email} tried to create a new folder with title #{folder_title}, but it already has a folder with that title"
      raise FolderAlreadyExistsError.new
    end

    Rails.logger.info "Creating folder with title #{folder_title} for user #{user.id} - #{user.email}"
    folder = user.folders.create title: folder_title
    return folder
  end

  private

  ##
  # Sanitize the title of the folder.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_fields
    self.title = sanitize self.title
  end

  ##
  # Before adding a feed to a folder, ensure that the feed is not already in other folders that belong
  # to the same user. In this case, raise a rollback error.

  def single_user_folder(feed)
    if feed.folders.present?
      raise ActiveRecord::Rollback if feed.folders.where(user_id: self.user_id).exists?
    end
  end
end
