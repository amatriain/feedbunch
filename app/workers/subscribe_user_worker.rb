##
# Background job to subscribe a user to a feed and, optionally, put the feed in a folder.
#
# This is a Sidekiq worker

class SubscribeUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :interactive

  ##
  # Subscribe a user to a feed and optionally put the feed in a folder
  #
  # Receives as arguments:
  # - id of the user
  # - url of the feed
  # - id of the folder. It must be owned by the user. If a nil is passed, ignore it
  # - boolean indicating whether the subscription is part of an OPML import process
  # - id of the SubscribeJobState instance that reflects the state of the job. If a nil is passed, ignore it.
  #
  # If requested, the opml_import_job_state of the user is updated so that the user can see the import progress.
  #
  # If a job_state_id is passed, the state field of the SubscribeJobState instance will be updated when
  # the job finishes, to reflect whether it finished successfully or with an error.
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(user_id, feed_url, folder_id, running_opml_import_job, job_state_id)
    # Find the SubscribeJobState instance for this job, if it exists
    if job_state_id.present?
      if SubscribeJobState.exists? job_state_id
        job_state = SubscribeJobState.find job_state_id
        # Check that the subscribe_job_state is in state "RUNNING"
        if job_state.state != SubscribeJobState::RUNNING
          Rails.logger.warn "Processing SubscribeUserWorker for subscribe_job_state_id #{job_state_id}, it should be in state RUNNING but it is in state #{job_state.state}. Aborting."
          return
        end
      end
    end

    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to add subscription to non-existing user @#{user_id}, aborting job"
      job_state.destroy if job_state.present?
      return
    end
    user = User.find user_id

    # Check if the folder actually exists and is owned by the user
    if folder_id.present?
      if !Folder.exists? folder_id
        Rails.logger.error "Trying to add subscription in non-existing folder @#{folder_id}, aborting job"
        job_state.destroy if job_state.present?
        return
      end
      folder = Folder.find folder_id
      if !user.folders.include? folder
        Rails.logger.error "Trying to add subscription in folder #{folder.id} - #{folder.title} which is not owned by user #{user.id} - #{user.email}, aborting job"
        job_state.destroy if job_state.present?
        return
      end
    end

    # Check that user has a opml_import_job_state with state RUNNING if requested to update it
    if running_opml_import_job
      if user.opml_import_job_state.try(:state) != OpmlImportJobState::RUNNING
        Rails.logger.error "User #{user.id} - #{user.email} does not have a data import with state RUNNING, aborting job"
        job_state.destroy if job_state.present?
        return
      end
    end

    feed = subscribe_feed feed_url, user, folder

    # Set job state to "SUCCESS" and save the id of the actually subscribed feed
    job_state.update state: SubscribeJobState::SUCCESS, feed_id: feed.id if job_state.present?
  rescue RestClient::Exception,
      RestClient::RequestTimeout,
      SocketError,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      AlreadySubscribedError,
      EmptyResponseError,
      FeedAutodiscoveryError,
      FeedFetchError,
      OpmlImportError => e
    # all these errors mean the feed cannot be subscribed, but the job itself has not failed. Do not re-raise the error
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    job_state.update state: SubscribeJobState::ERROR if job_state.present?
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    job_state.update state: SubscribeJobState::ERROR if job_state.present?
    # The job has failed. Re-raise the exception so that Resque takes care of it
    raise e
  ensure
    # Once finished, mark import state as SUCCESS if requested.
    update_import_state user, feed_url, folder_id if running_opml_import_job && user.try(:opml_import_job_state).present?
  end

  private

  ##
  # Sets the opml_import_job_state state for the user as SUCCESS.
  #
  # Receives as argument the user whose import process has finished successfully, the
  # URL of the feed just subscribed, and the ID of the folder into which the feed as been moved.

  def update_import_state(user, feed_url, folder_id)
    processed_feeds = user.opml_import_job_state.processed_feeds + 1
    user.opml_import_job_state.update processed_feeds: processed_feeds
    if import_finished? user, feed_url, folder_id
      user.opml_import_job_state.state = OpmlImportJobState::SUCCESS
      user.opml_import_job_state.save
      Rails.logger.info "Sending data import success email to user #{user.id} - #{user.email}"
      OpmlImportMailer.import_finished_success_email(user).deliver
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
  #
  # Returns the subscribed feed

  def subscribe_feed(url, user, folder)
    Rails.logger.info "Subscribing user #{user.id} - #{user.email} to feed #{url}"
    feed = user.subscribe url
    if folder.present? && feed.present?
      Rails.logger.info "As part of OPML import, moving feed #{feed.id} - #{feed.title} to folder #{folder.title} owned by user #{user.id} - #{user.email}"
      folder.feeds << feed
    end
    return feed
  end

  ##
  # Check if the OPML import process has finished.
  #
  # Receives as argument the user whose import process is to be checked, the URL of
  # the feed just subscribed, and the ID of the folder into which it's been moved.
  #
  # Returns a boolean: true if import is finished, false otherwise.

  def import_finished?(user, feed_url, folder_id)
    # If the number of processed feeds equals the total number of feeds in the OPML, import is finished
    if user.opml_import_job_state.processed_feeds >= user.opml_import_job_state.total_feeds
      return true
    end

    # If other jobs part of the same OPML import are still running, import process is not finished
    if other_jobs_running? user, feed_url, folder_id
      return false
    # If a SubscribeUserWorker is enqueued, import process is not finished
    elsif other_jobs_enqueued? user, feed_url, folder_id
      return false
    # If no jobs related to the import are running or queued, the import process has finished
    else
      return true
    end
  end

  ##
  # Check if other jobs part of an OPML import for the passed user are currently running, besides
  # this one.
  #
  # Receives as arguments: user who is running the OPML import, URL of the feed being subscribed by this job,
  # ID of the destination folder for this job.
  #
  # Other jobs part of the same OPML import should be instances of ImportSubscriptionsWorker (the main import job)
  # or SubscribeUserWorker (the subscribe jobs launched by the main import job), and they should share arguments.
  #
  # Returns true if other jobs part of the same OPML import are still running, false otherwise.

  def other_jobs_running?(user, feed_url, folder_id)
    other_jobs_running = false

    workers = Sidekiq::Workers.new
    workers.each do |process_id, thread_id, work|
      working_class = work['payload']['class']
      if working_class == 'ImportSubscriptionsWorker'
        # As soon as a single job matching the conditions is found, we can return "true", no need
        # to keep looking at the rest of jobs
        if work['payload']['args'][1] == user.id
          other_jobs_running = true
          break
        end
      elsif working_class == 'SubscribeUserWorker'
        args = work['payload']['args']
        # As soon as a single job matching the conditions is found, we can return "true", no need
        # to keep looking at the rest of jobs
        if args[0] == user.id && (args[1] != feed_url || args[2] != folder_id) && args[3] == true
          other_jobs_running = true
          break
        end
      end
    end

    return other_jobs_running
  end

  ##
  # Check if other jobs part of an OPML import for the passed user are currently enqueued.
  #
  # Receives as arguments: user who is running the OPML import, URL of the feed being subscribed by this job,
  # ID of the destination folder for this job.
  #
  # Other jobs part of the same OPML import should be instances of SubscribeUserWorker (the subscribe jobs
  # launched by the main import job), and they should share arguments.
  #
  # Returns true if other jobs part of the same OPML import are enqueued, false otherwise.

  def other_jobs_enqueued?(user, feed_url, folder_id)
    other_jobs_enqueued = false

    queue = Sidekiq::Queue.new 'interactive'
    queue.each do |job|
      if job.klass == 'SubscribeUserWorker'
        args = job.args
        # As soon as a single job matching the conditions is found, we can return "true", no need
        # to keep looking at the rest of jobs
        if args[0] == user.id && (args[1] != feed_url || args[2] != folder_id) && args[3] == true
          other_jobs_enqueued = true
          break
        end
      end
    end

    return other_jobs_enqueued
  end

end