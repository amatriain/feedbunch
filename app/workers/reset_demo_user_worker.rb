##
# Background worker to create the demo user (if it doesn't exist yet) and reset its configuration, folders and
# subscribed feeds.
#
# The credentials for the demo user are:
# - email: demo@feedbunch.com
# - password: feedbunch-demo
#
# This is a Sidekiq worker

class ResetDemoUserWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance
  # Run every hour.
  recurrence do
    hourly
  end

  ##
  # Store config values in instance variables, for DRYer code.

  def initialize
    @demo_email = Feedbunch::Application.config.demo_email
    @demo_password = Feedbunch::Application.config.demo_password
    @demo_name = Feedbunch::Application.config.demo_name
    @demo_locale = I18n.default_locale
    @demo_timezone = Feedbunch::Application.config.time_zone
    @demo_quick_reading = Feedbunch::Application.config.demo_quick_reading
    @demo_open_all_entries = Feedbunch::Application.config.demo_open_all_entries
    @demo_feeds_and_folders = Feedbunch::Application.config.demo_subscriptions
  end

  ##
  # Create the demo user if it still doesn't exist. Reset its configuration, folders and subscribed feeds.

  def perform
    Rails.logger.debug 'Resetting demo user'

    unless Feedbunch::Application.config.demo_enabled
      Rails.logger.debug 'Demo user is disabled'
      # If the demo user is disabled in the configuration, just destroy it if it exists and do nothing else.
      destroy_demo_user
      return
    end

    demo_user = create_demo_user
    reset_demo_config demo_user
    reset_job_states demo_user
    reset_feeds_and_folders demo_user
  end

  private

  ##
  # Destroy the demo user, if it exists.

  def destroy_demo_user
    if User.exists? email: @demo_email
      Rails.logger.warn 'Demo user disabled but exists in the database. Destroying it.'
      demo_user = User.find_by_email @demo_email
      demo_user.destroy
    end
  end

  ##
  # Create the demo user, if it doesn't exist.
  # Returns the demo user, either just created or previously existing.

  def create_demo_user
    if User.exists? email: @demo_email
      demo_user = User.find_by_email @demo_email
    else
      demo_user = User.new email: @demo_email,
                           password: @demo_password,
                           confirmed_at: Time.zone.now,
                           free: true
      Rails.logger.debug 'Demo user does not exist, creating it'
      demo_user.save!
    end
    return demo_user
  end

  ##
  # Reset config values for the demo user to their default values.
  # Receives as argument the demo user.

  def reset_demo_config(demo_user)
    Rails.logger.debug 'Resetting default config values for the demo user'
    demo_user.name = @demo_name
    demo_user.admin = false
    demo_user.locale = @demo_locale
    demo_user.timezone = @demo_timezone
    demo_user.quick_reading = @demo_quick_reading
    demo_user.open_all_entries = @demo_open_all_entries
    demo_user.invitation_limit = 0
    demo_user.show_main_tour = true
    demo_user.show_mobile_tour = true
    demo_user.show_feed_tour = true
    demo_user.show_entry_tour = true
    demo_user.free = true
    demo_user.save!
  end

  ##
  # Reset state of all jobs (OPML import and export, subscribe and refresh) started by the user.
  # Receives as argument the demo user.

  def reset_job_states(demo_user)
    Rails.logger.debug 'Resetting job states for the demo user'
    demo_user.opml_import_job_state.try :destroy
    demo_user.create_opml_import_job_state state: OpmlImportJobState::NONE
    demo_user.opml_export_job_state.try :destroy
    demo_user.create_opml_export_job_state state: OpmlExportJobState::NONE
    demo_user.subscribe_job_states.destroy_all
    demo_user.refresh_feed_job_states.destroy_all
  end

  ##
  # Reset folders and subscribed feeds.
  # Receives as argument the demo user.

  def reset_feeds_and_folders(demo_user)
    Rails.logger.debug 'Resetting feeds and folders for the demo user'

    # destroy all folders and unsubscribe all feeds
    demo_user.feeds.find_each { |f| demo_user.unsubscribe f}
    demo_user.folders.destroy_all
    demo_user.reload

    @demo_feeds_and_folders.keys.each do |folder_title|
      # the special value "NO FOLDER" is not an actual folder, we don't create it
      folder = demo_user.folders.create title: folder_title unless folder_title == Folder::NO_FOLDER
      @demo_feeds_and_folders[folder_title].each do |feed_url|
        feed = demo_user.subscribe feed_url
        folder.feeds << feed unless folder.blank?
      end
    end
  end

  ##
  # From the feeds/folders hash stored in the @demo_feeds_and_folders variable, returns a flat array with
  # the feed URLs the demo user should be subscribed to.

  def demo_subscriptions_list
    return @demo_feeds_and_folders.values.flatten
  end

  ##
  # Unsuscribe demo user from any feeds that have been added besides the defaults.
  # Receives as arguments the demo user and an array with the URLs of the default subscriptions of the demo user.

  def unsubscribe_extra_feeds(demo_user, demo_subscriptions)
    demo_user.feeds.find_each do |feed|
      # TODO
    end
  end
end