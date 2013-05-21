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
  has_and_belongs_to_many :feeds, uniq: true, before_add: :single_user_folder, after_remove: :remove_empty_folders
  has_many :entries, through: :feeds

  validates :title, presence: true, uniqueness: {case_sensitive: false, scope: :user_id}

  before_validation :sanitize_fields

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
  # Before adding a feed to a folder, check if the feed is already in another folder owned
  # by the same user. In this case, remove it from the old folder before adding it to the new one.

  def single_user_folder(feed)
    old_folder = feed.folders.where(user_id: self.user_id).first
    if old_folder.present?
      old_folder.feeds.delete feed
    end
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
