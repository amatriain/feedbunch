##
# Background job to subscribe a user to a feed and, optionally, put the feed in a folder.
#
# Its perform method will be invoked from a Resque worker.

class SubscribeUserJob
  @queue = :update_feeds

  ##
  # Subscribe a user to a feed and optionally put the feed in a folder
  #
  # Receives as arguments:
  # - id of the user
  # - url of the feed
  # - id of the folder. It must be owned by the user. If a nil is passed, ignore it
  # - boolean indicating whether to update the user's running data_import
  #
  # If requested, the data_import of the user is updated so that the user can see the import progress.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(user_id, feed_url, folder_id, update_import)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to add subscription to non-existing user @#{user_id}, aborting job"
      return
    end
    user = User.find user_id

    # Check if the folder actually exists and is owned by the user
    if folder_id.present?
      if !Folder.exists? folder_id
        Rails.logger.error "Trying to add subscription in non-existing folder @#{folder_id}, aborting job"
        return
      end
      folder = Folder.find folder_id
      if !user.folders.include? folder
        Rails.logger.error "Trying to add subscription in folder #{folder.id} - #{folder.title} which is not owned by user #{user.id} - #{user.email}, aborting job"
        return
      end
    end

    # Check that user has a data_import with status RUNNING if requested to update it
    if update_import
      if user.data_import.try(:status) != DataImport::RUNNING
        Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with status RUNNING, aborting job"
        return
      end
    end

    self.subscribe_feed feed_url, user, folder
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    # Re-raise the exception so that Resque takes care of it
    raise e
  ensure
    # Once finished, mark import status as SUCCESS if requested.
    self.update_import_status user if update_import
  end

  private

  ##
  # Sets the data_import status for the user as SUCCESS.
  #
  # Receives as argument the user whose import process has finished successfully.

  def self.update_import_status(user)
    user.data_import.processed_feeds += 1
    user.data_import.save
    if user.data_import.total_feeds == user.data_import.processed_feeds
      user.data_import.status = DataImport::SUCCESS
      user.data_import.save
      Rails.logger.info "Sending data import success email to user #{user.id} - #{user.email}"
      DataImportMailer.import_finished_success_email(user).deliver
    end
  end

  ##
  # Subscribe a user to a feed.
  #
  # Receives as arguments:
  # - the url of the feed
  # - the user who requested the import (and who will be subscribed to the feed)
  # - optionally, the folder in which the feed will be (defaults to none)
  #
  # If the feed already exists in the database, the user is subscribed to it.

  def self.subscribe_feed(url, user, folder)
    Rails.logger.info "Subscribing user #{user.id} - #{user.email} to feed #{url}"
    feed = user.subscribe url
    if folder.present? && feed.present?
      Rails.logger.info "As part of OPML import, moving feed #{feed.id} - #{feed.title} to folder #{folder.title} owned by user #{user.id} - #{user.email}"
      folder.feeds << feed
    end
  end
end