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
  # - boolean indicating whether the subscription is part of an OPML import process
  #
  # If requested, the data_import of the user is updated so that the user can see the import progress.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(user_id, feed_url, folder_id, running_data_import)
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

    # Check that user has a data_import with state RUNNING if requested to update it
    if running_data_import
      if user.data_import.try(:state) != DataImport::RUNNING
        Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with state RUNNING, aborting job"
        return
      end
    end

    self.subscribe_feed feed_url, user, folder
  rescue RestClient::Exception, SocketError, Errno::ETIMEDOUT, AlreadySubscribedError, EmptyResponseError, FeedAutodiscoveryError, FeedFetchError, FeedParseError, ImportDataError => e
    # all these errors mean the feed cannot be subscribed, but the job itself has not failed. Do not re-raise the error
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    # The job has failed. Re-raise the exception so that Resque takes care of it
    raise e
  ensure
    # Once finished, mark import state as SUCCESS if requested.
    self.update_import_state user, feed_url, folder_id if running_data_import && user.try(:data_import).present?
  end

  private

  ##
  # Sets the data_import state for the user as SUCCESS.
  #
  # Receives as argument the user whose import process has finished successfully, the
  # URL of the feed just subscribed, and the ID of the folder into which the feed as been moved.

  def self.update_import_state(user, feed_url, folder_id)
    user.data_import.processed_feeds += 1
    user.data_import.save
    if self.import_finished? user, feed_url, folder_id
      user.data_import.state = DataImport::SUCCESS
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

  ##
  # Check if the OPML import process has finished (all enqueued jobs have finished running).
  #
  # Receives as argument the user whose import process is to be checked, the URL of
  # the feed just subscribed, and the ID of the folder into which it's been moved.
  #
  # Returns a boolean: true if import is finished, false otherwise.

  def self.import_finished?(user, feed_url, folder_id)
    # If the number of processed feeds equals the total number of feeds in the OPML, import is finished
    if user.data_import.processed_feeds == user.data_import.total_feeds
      return true
    end

    # If a ImportSubscriptionJob or another SubscribeUserJob for the user is still running, import process is not finished
    Resque.working.each do |w|
      working_class = w.job['payload']['class']
      if working_class == 'ImportSubscriptionsJob'
        return false if w.job['payload']['args'][1] == user.id
      elsif working_class == 'SubscribeUserJob'
        args = w.job['payload']['args']
        return false if args[0] == user.id && (args[1] != feed_url || args[2] != folder_id) && args[3] == true
      end
    end

    # If a SubscribeUserJob is enqueued, import process is not finished
    peek_start = 0
    job = Resque.peek 'update_feeds', peek_start
    while job.present?
      if job['class'] == 'SubscribeUserJob'
        args = job['args']
        return false if args[0] == user.id && (args[1] != feed_url || args[2] != folder_id) && args[3] == true
      end
      peek_start += 1
      job = Resque.peek 'update_feeds', peek_start
    end

    # If no jobs related to the import are running or queued, the import process has finished
    return true
  end
end