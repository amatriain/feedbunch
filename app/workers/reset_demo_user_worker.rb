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

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

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
    demo_user.show_kb_shortcuts_tour = true
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

    demo_feed_urls = demo_subscriptions_list
    reset_feed_subscriptions demo_user, demo_feed_urls

    # Mark all entries as unread
    demo_user.entry_states.update_all read: false

    reset_folders demo_user

    # Finally move feeds to their right folders
    @demo_feeds_and_folders.keys.each do |folder_title|
      # the special value "NO FOLDER" is not an actual folder, skip it
      if folder_title != Folder::NO_FOLDER
        folder = demo_user.folders.find_by_title folder_title

        @demo_feeds_and_folders[folder_title].each do |feed_url|
          feed = Feed.url_variants_feed feed_url

          # Only move feed to different folder if necessary
          current_folder = feed.user_folder demo_user
          if current_folder != folder
            Rails.logger.debug "Demo user - moving feed #{feed.id} - #{feed.fetch_url} to folder #{folder_title}"
            folder.feeds << feed unless folder.blank?
          else
            Rails.logger.debug "Demo user - feed #{feed.fetch_url} is already in default folder #{folder_title}"
          end
        end
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
  # Subscribe demo user to any feeds missing from the defaults, and unsubscribe from any feeds not in the defaults.
  # Receives as arguments the demo user and an array with the default feed URLs.
  # After this method is finished, it is guaranteed that the demo user is subscribed exactly to the default feeds.
  # However it is not guaranteed that feeds are in the correct folders.

  def reset_feed_subscriptions(demo_user, demo_feed_urls)
    already_subscribed_default_urls = []
    not_subscribed_default_urls = []

    # Find out which of the default feed urls are already subscribed by the demo user, and which ones are not
    demo_feed_urls.each do |url|
      feed = Feed.url_variants_feed url
      if feed.present?
        subscribed_feed = demo_user.feeds.find_by id: feed.id
        if subscribed_feed.present?
          Rails.logger.debug "Demo user already subscribed to feed #{url}"
          already_subscribed_default_urls << subscribed_feed.fetch_url
        else
          Rails.logger.debug "Demo user not subscribed to existing feed #{url}"
          not_subscribed_default_urls << url
        end
      else
        Rails.logger.debug "Demo feed #{url} does not exist in the database"
        not_subscribed_default_urls << url
      end
    end

    # Unsubscribe feeds not in the list of demo feed urls
    demo_user.feeds.find_each do |feed|
      unless already_subscribed_default_urls.include? feed.fetch_url
        Rails.logger.debug "Unsubscribing demo user from feed not in defaults: #{feed.id} - #{feed.fetch_url}"
        demo_user.unsubscribe feed
      end
    end

    # Subscribe to missing demo feeds
    not_subscribed_default_urls.each do |url|
      Rails.logger.debug "Subscribing demo user to missing default feed #{url}"
      demo_user.subscribe url
    end
  end

  ##
  # Create missing default folders for the demo user, and destroy any folders not in the defaults.
  # Receives as argument the demo user.

  def reset_folders(demo_user)
    already_existing_default_folders = []
    not_existing_default_folders = []

    # Find out which folders are already created and which ones are not
    @demo_feeds_and_folders.keys.each do |folder_title|
      # the special value "NO FOLDER" is not an actual folder, skip it
      if folder_title != Folder::NO_FOLDER
        if demo_user.folders.find_by(title: folder_title).present?
          Rails.logger.debug "Demo user already has folder #{folder_title}"
          already_existing_default_folders << folder_title
        else
          Rails.logger.debug "Demo user does not have folder #{folder_title}"
          not_existing_default_folders << folder_title
        end
      end
    end

    # Destroy folders not in the defaults
    demo_user.folders.find_each do |folder|
      unless already_existing_default_folders.include? folder.title
        Rails.logger.debug "Destroying folder owned by demo user but not in the default list: #{folder.id} - #{folder.title}"
        folder.destroy
      end
    end

    # Create missing folders
    not_existing_default_folders.each do |folder_title|
      Rails.logger.debug "Creating for the demo user missing folder #{folder_title}"
      demo_user.folders.create title: folder_title
    end
  end
end