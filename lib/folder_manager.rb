##
# This class has methods related to managing the relationships between feeds and folders.

class FolderManager

  ##
  # Move a feed into a folder, for a given user.
  #
  # Receives as arguments:
  #
  # - feed_id: mandatory. ID of the feed to be moved.
  # - user: mandatory. User who is moving the feed. User must be subscribed to the feed and own the folder.
  # - folder_id: optional named argument. If present, moves the feed to the folder with this ID, which must be owned by
  # the passed user; in this case, ignores the folder_title argument.
  # Accepts the special value "none", which means that the feed will be removed from its current folder without moving
  # it to another one.
  # - folder_title: optional named argument. If present, and folder_id is not present, create a new folder with this
  # title (owned by the passed user) and move the feed to it.
  #
  # Returns a hash with the following values:
  # - :feed => the feed which has been moved
  # - :new_folder => the folder to which the feed has been moved (unless folder_id=='none', in which case this key is
  # not present)
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present.

  def self.move_feed_to_folder(feed_id, user, folder_id: nil, folder_title: nil)
    if folder_id.present? && folder_id != Folder::NO_FOLDER
      changes = self.move_feed_to_existing_folder feed_id, folder_id, user
    elsif  folder_id == Folder::NO_FOLDER
      changes = self.remove_feed_from_folder feed_id, user
    else
      changes = self.move_feed_to_new_folder feed_id, folder_title, user
    end

    return changes
  end

  private

  ##
  # Move a feed to an existing folder.
  #
  # Receives as arguments the id of the feed, the id of the folder and the user instance which is subscribed
  # to the feed and who owns the folder.
  #
  # The folder must belong to the user, and the user must be subscribed to the feed. If any of these
  # conditions is not met, an ActiveRecord::RecordNotFound error is raised.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :feed => the feed which has been added to the folder
  # - :new_folder => the folder to which the feed has been added
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash
  #
  # If the method detects that the feed is being moved to the same folder it's already at, no action is
  # taken at the database level, and the return hash has the same values in the :new_folder and :old_folder keys.

  def self.move_feed_to_existing_folder(feed_id, folder_id, user)
    # Ensure the user is subscribed to the feed and the folder is owned by the user.
    feed = user.feeds.find feed_id
    folder = user.folders.find folder_id

    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder user

    if folder == old_folder
      Rails.logger.info "user #{user.id} - #{user.email} is trying to add feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}, but the feed is already in that folder"
    else
      Rails.logger.info "user #{user.id} - #{user.email} is adding feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}"
      folder.feeds << feed
    end

    changes = {}
    changes[:new_folder] = folder.reload
    changes[:feed] = feed.reload
    changes[:old_folder] = old_folder if old_folder.present?

    return changes
  end

  ##
  # Create a new folder owned by the user, and move a feed to it.
  #
  # Receives as arguments the id of the feed, the title of the new folder and the user who will own the folder.
  #
  # If the user already has a folder with the same title, raises a FolderAlreadyExistsError.
  # If the user is not subscribed to the feed, raises an ActiveRecord::RecordNotFound error.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :feed => the feed which has been added to the folder
  # - :new_folder => the folder to which the feed has been added
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash

  def self.move_feed_to_new_folder(feed_id, folder_title, user)
    # Ensure that user is subscribed to the feed
    feed = user.feeds.find feed_id

    if user.folders.where(title: folder_title).present?
      Rails.logger.info "User #{user.id} - #{user.email} tried to create a new folder with title #{folder_title}, but it already has a folder with that title"
      raise FolderAlreadyExistsError.new
    end

    Rails.logger.info "Creating folder with title #{folder_title} for user #{user.id} - #{user.email}"
    folder = user.folders.create title: folder_title

    changes = self.move_feed_to_existing_folder feed.id, folder.id, user
    return changes
  end

  ##
  # Remove a feed from its current folder.
  #
  # Receives as arguments the id of the feed and the user instance who is removing the feed. The user must
  # be subscribed to the feed.
  #
  # If there are no more feeds in the folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :feed => the feed which has been added to the folder
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash

  def self.remove_feed_from_folder(feed_id, user)
    # Ensure the user is subscribed to the feed and the folder is owned by the user.
    feed = user.feeds.find feed_id

    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder user

    if old_folder.present?
      Rails.logger.info "user #{user.id} - #{user.email} is removing feed #{feed.id} - #{feed.fetch_url} from folder #{old_folder.id} - #{old_folder.title}"
      feed.remove_from_folder user
    else
      Rails.logger.info "user #{user.id} - #{user.email} tried to remove feed #{feed.id} - #{feed.fetch_url} from its folder, but it's not in any folder"
    end

    changes = {}
    changes[:feed] = feed.reload
    changes[:old_folder] = old_folder if old_folder.present?

    return changes
  end
end