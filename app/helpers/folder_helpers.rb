##
# Module with functions related to adding and removing feeds from folders

module FolderHelpers

  ##
  # Add a feed to a folder.
  #
  # Receives as arguments the id of the feed and the id of the folder.
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

  def add_feed_to_folder(feed_id, folder_id)
    # Ensure the user is subscribed to the feed and the folder is owned by the user.
    feed = self.feeds.find feed_id
    folder = self.folders.find folder_id

    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder self

    Rails.logger.info "user #{self.id} - #{self.email} is adding feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}"
    folder.feeds << feed

    changes = {}
    changes[:new_folder] = folder.reload
    changes[:feed] = feed.reload
    changes[:old_folder] = old_folder if old_folder.present?

    return changes
  end

  ##
  # Create a new folder owned by the user, and add a feed to it.
  #
  # Receives as arguments the id of the feed and the title of the new folder.
  #
  # If the user already has a folder with the same title, raises a FolderAlreadyExistsError.
  # If the user is not subscribed to the feed, raises an ActiveRecord::RecordNotFound error.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :new_folder => the newly created folder to which the feed has been added
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash

  def add_feed_to_new_folder(feed_id, folder_title)
    # Ensure that user is subscribed to the feed
    feed = self.feeds.find feed_id

    if self.folders.where(title: folder_title).present?
      Rails.logger.info "User #{self.id} - #{self.email} tried to create a new folder with title #{folder_title}, but it already has a folder with that title"
      raise FolderAlreadyExistsError.new
    end

    Rails.logger.info "Creating folder with title #{folder_title} for user #{self.id} - #{self.email}"
    folder = self.folders.create title: folder_title

    changes = self.add_feed_to_folder feed.id, folder.id
    # Only return the :old_folder, :new_folder keys
    return changes.except :feed
  end

  ##
  # Remove a feed from its current folder, ir any.
  #
  # Receives as argument the id of the feed.
  #
  # A feed can only be in a single folder owned by a given user, so it's not necessary to pass the folder id
  # as an argument, it can be inferred from the user id and feed id.
  #
  # The user must be subscribed to the feed. Otherwise an ActiveRecord::RecordNotFound
  # error is raised.
  #
  # If after removing the feed there are no more feeds in the folder, it is deleted.
  #
  # Returns a boolean:
  # - true if the folder has not been deleted (it has more feeds in it)
  # - false if the folder has been deleted (it had no more feeds)

  def remove_feed_from_folder(feed_id)
    # Ensure that the user is subscribed to the feed
    feed = self.feeds.find feed_id

    folder = feed.user_folder self
    if folder.present?
      Rails.logger.info "user #{self.id} - #{self.email} is removing feed #{feed.id} - #{feed.fetch_url} from folder #{folder.id} - #{folder.title}"
      folder.feeds.delete feed
      return !folder.destroyed?
    else
      Rails.logger.info "user #{self.id} - #{self.email} is trying to remove feed #{feed.id} - #{feed.fetch_url} from its folder, but it's not in any folder"
      return true
    end

  end
end