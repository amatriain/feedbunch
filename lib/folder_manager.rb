##
# This class has methods related to managing the relationships between feeds and folders.

class FolderManager

  ##
  # Move a feed into a folder, for a given user.
  #
  # Receives as arguments:
  #
  # - feed: mandatory. Feed to be moved.
  # - user: mandatory. User who is moving the feed. User must be subscribed to the feed and own the folder.
  # - folder: optional named argument. If present, moves the feed to this folder, which must be owned by
  # the passed user; in this case, ignores the folder_title argument.
  # Accepts the special value "none", which means that the feed will be removed from its current folder without moving
  # it to another one.
  # - folder_title: optional named argument. If present, and the folder argument is not present, create a new folder with this
  # title (owned by the passed user) and move the feed to it.
  #
  # Returns the folder instance to which the feed has been moved, or nil if "none" has been passed
  # in the "folder" argument.
  #
  # Raises a NotSubscribedError if the user is not subscribed to the feed.

  def self.move_feed_to_folder(feed, user, folder: nil, folder_title: nil)
    if !user.feeds.exists? feed
      raise NotSubscribedError.new
    end

    if folder.present? && folder != Folder::NO_FOLDER
      folder = self.move_feed_to_existing_folder feed, folder, user
    elsif  folder == Folder::NO_FOLDER
      folder = self.remove_feed_from_folder feed, user
    else
      folder = self.move_feed_to_new_folder feed, folder_title, user
    end

    return folder
  end

  private

  ##
  # Move a feed to an existing folder.
  #
  # Receives as arguments the feed, the folder and the user instance which is subscribed
  # to the feed and who owns the folder.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # If the method detects that the feed is being moved to the same folder it's already at, no action is
  # taken.
  #
  # Returns the folder instance to which the feed has been moved

  def self.move_feed_to_existing_folder(feed, folder, user)
    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder user

    if folder == old_folder
      Rails.logger.info "user #{user.id} - #{user.email} is trying to add feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}, but the feed is already in that folder"
    else
      Rails.logger.info "user #{user.id} - #{user.email} is adding feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}"
      folder.feeds << feed
    end

    return folder
  end

  ##
  # Create a new folder owned by the user, and move a feed to it.
  #
  # Receives as arguments the feed, the title of the new folder and the user who will own the folder.
  #
  # If the user already has a folder with the same title, raises a FolderAlreadyExistsError.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns the folder instance to which the feed has been moved.

  def self.move_feed_to_new_folder(feed, folder_title, user)
    if user.folders.where(title: folder_title).present?
      Rails.logger.info "User #{user.id} - #{user.email} tried to create a new folder with title #{folder_title}, but it already has a folder with that title"
      raise FolderAlreadyExistsError.new
    end

    Rails.logger.info "Creating folder with title #{folder_title} for user #{user.id} - #{user.email}"
    folder = user.folders.create title: folder_title
    self.move_feed_to_existing_folder feed, folder, user
    return folder
  end

  ##
  # Remove a feed from its current folder.
  #
  # Receives as arguments the feed and the user instance who is removing the feed. The user must
  # be subscribed to the feed.
  #
  # If there are no more feeds in the folder, it is deleted.
  #
  # Returns nil.

  def self.remove_feed_from_folder(feed, user)
    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder user

    if old_folder.present?
      Rails.logger.info "user #{user.id} - #{user.email} is removing feed #{feed.id} - #{feed.fetch_url} from folder #{old_folder.id} - #{old_folder.title}"
      feed.remove_from_folder user
    else
      Rails.logger.info "user #{user.id} - #{user.email} tried to remove feed #{feed.id} - #{feed.fetch_url} from its folder, but it's not in any folder"
    end

    return nil
  end
end