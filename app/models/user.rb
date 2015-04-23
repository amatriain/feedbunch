require 'folder_manager'
require 'url_subscriber'
require 'feed_refresh_manager'
require 'entry_state_manager'
require 'entries_pagination'
require 'feeds_pagination'
require 'opml_importer'
require 'subscriptions_manager'
require 'etag_calculator'

##
# User model. Each instance of this class represents a single user that can log in to the application
# (or at least that has passed through the signup process but has not yet confirmed his email).
#
# This class has been created by installing the Devise[https://github.com/plataformatec/devise] gem and
# running the following commands:
#   rails generate devise:install
#   rails generate devise User
#
# The Devise[https://github.com/plataformatec/devise] gem manages authentication in this application. To
# learn more about Devise visit:
# {https://github.com/plataformatec/devise}[https://github.com/plataformatec/devise]
#
# Beyond the attributes added to this class by Devise[https://github.com/plataformatec/devise] for authentication,
# Feedbunch establishes relationships between the User model and the following models:
#
# - FeedSubscription: Each user can be subscribed to many feeds, but a single subscription belongs to a single user (one-to-many relationship).
# - Feed, through the FeedSubscription model: This enables us to retrieve the feeds a user is subscribed to.
# - Folder: Each user can have many folders and each folder belongs to a single user (one-to-many relationship).
# - Entry, through the Feed model: This enables us to retrieve all entries for all feeds a user is subscribed to.
# - EntryState: This enables us to retrieve the state (read or unread) of all entries for all feeds a user is subscribed to.
# - OpmlImportJobState: This indicates whether the user has ever started an OPML import, and in this case it gives information about the import
# process (whether it's still running or not, number of feeds processed, etc).
# - OpmlExportJobState: This indicates whether the user has ever started an OPML export, and in this case it gives information about the import
# process state.
# - RefreshFeedJobState: Each instance of this class associated with a user represents an ocurrence of the user requesting
# a refresh of a feed. The state attribute of the instance indicates if the refresh is running, successfully finished,
# or finished with an error.
# - SubscribeJobState: Each instance of this class associated with a user represents an ocurrence of the user trying
# to subscribe to a feed. The state attribute of the instance indicates if the subscription is running, successfully
# finished or finished with an error.
#
# Also, the User model has the following attributes:
#
# - admin: Boolean that indicates whether the user is an administrator. This attribute is used to restrict access to certain
# functionality, like ActiveAdmin and Sidekiq administration.
# - free: Boolean that indicates if the user has been granted free access to the app (if true) or if he's a paying user (if false).
# Note that regular users have this attribute set to false, even during any unpaid trial period. Only users who are never
# required to pay anything have this attribute set to true.
# - name: text with the username, to be displayed in the app. Usernames are unique. Defaults to the value of the "email" attribute.
# - locale: locale (en, es etc) in which the user wants to see the application. By default "en".
# - timezone: name of the timezone (Europe/Madrid, UTC etc) to which the user wants to see times localized. By default "UTC".
# - quick_reading: boolean indicating whether the user has enabled Quick Reading mode (in which entries are marked as read
# as soon as they are scrolled by) or not. False by default.
# - open_all_entries: boolean indicating whether the user wants to see all entries open by default when they are loaded.
# False by default.
# - show_main_tour: boolean indicating whether the main app tour should be shown when the user enters the application. True
# by default
# - show_mobile_tour: boolean indicating whether the mobile app tour should be shown when the user enters the application.
# True by default.
# - show_feed_tour: boolean indicating whether the feed tour should be shown. True by default.
# - show_entry_tour: boolean indicating whether the entry tour should be shown. True by default.
# - subscriptions_updated_at: datetime when subscriptions were updated for the last time. Events that
# update this attribute are:
#   - subscribing to a new feed
#   - unsubscribing from a feed
#   - changing the unread entries count for a feed
#   - changing a feed title
#   - changing a feed URL
#   - moving a feed into or out of a folder
# - folders_updated_at: datetime when folders were updated for the last time. Events that
# update this attribute are:
#   - creating a folder
#   - destroying a folder
# - refresh_feed_jobs_updated_at: datetime when refresh feed jobs for this user were updated for the last time.
# Events that update this attribute are:
#   - creating a refresh feed job state
#   - destroying a refresh feed job state
#   - updating a refresh feed job state
# - subscribe_jobs_updated_at: datetime when subscribe feed jobs for this user were updated for the last time.
# Events that update this attribute are:
#   - creating a subscribe feed job state
#   - destroying a subscribe feed job state
#   - updating a subscribe feed job state
# - config_updated_at: datetime when the config for this user was last updated. This attribute is
# updated every time one of these attributes is changed:
#   - quick_reading
#   - open_all_entries
#   - show_main_tour
#   - show_mobile_tour
#   - show_feed_tour
#   - show_entry_tour
# - user_data_updated_at: datetime when user data for this user was last updated. This attribute is
# updated every time one of these happens:
#   - user subscribes to a new feed
#   - user unsubscribes from a feed
# - first_confirmation_reminder_sent, first_confirmation_reminder_sent: booleans that indicates if the first and second
# confirmation reminder emails have been sent to a user. This happens when a user signs up but never clicks on the link
# in the confirmation email. Each of the two confirmation reminders will be sent just once.
#
# When a user is subscribed to a feed (this is, when a feed is added to the user.feeds array), EntryState instances
# are saved to mark all its entries as unread for this user.
#
# Conversely when a user unsubscribes from a feed (this is, when a feed is removed from the user.feeds array), all
# EntryState instances for its entries and for this user are deleted; the app does not store read/unread state for
# entries that belong to feeds to which the user is not subscribed.
#
# It is not mandatory that a user be suscribed to any feeds (in fact when a user first signs up he won't
# have any suscriptions).

class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  # Accessor to the unencrypted invitation token, to be able to resend invitations.
  attr_reader :raw_invitation_token

  has_many :invitations, class_name: self.to_s, as: :invited_by
  has_many :feed_subscriptions, -> {uniq}, dependent: :destroy,
           after_add: :mark_unread_entries,
           before_remove: :before_remove_feed_subscription,
           after_remove: :removed_feed_subscription
  has_many :feeds, through: :feed_subscriptions
  has_many :folders, -> {uniq}, dependent: :destroy
  has_many :entries, through: :feeds
  has_many :entry_states, -> {uniq}, dependent: :destroy
  has_one :opml_import_job_state, dependent: :destroy
  has_one :opml_export_job_state, dependent: :destroy
  has_many :refresh_feed_job_states, dependent: :destroy
  has_many :subscribe_job_states, dependent: :destroy

  validates :admin, inclusion: {in: [true, false]}
  validates :free, inclusion: {in: [true, false]}
  validates :name, presence: true, uniqueness: {case_sensitive: true}
  validates :locale, presence: true
  validates :timezone, presence: true
  validates :quick_reading, inclusion: {in: [true, false]}
  validates :open_all_entries, inclusion: {in: [true, false]}
  validates :show_main_tour, inclusion: {in: [true, false]}
  validates :first_confirmation_reminder_sent, inclusion: {in: [true, false]}
  validates :second_confirmation_reminder_sent, inclusion: {in: [true, false]}

  before_save :before_save_user
  after_save :after_save_user
  before_validation :default_values

  ##
  # Retrieves feeds subscribed by the user. See FeedsPagination#subscribed_feeds.

  def subscribed_feeds(include_read: false, page: nil)
    FeedsPagination.subscribed_feeds self, include_read: include_read, page: page
  end

  ##
  # Retrieves feeds subscribed by the user. See FolderManager#folder_feeds.

  def folder_feeds(folder, include_read: false)
    FolderManager.folder_feeds folder, self, include_read: include_read
  end

  ##
  # Retrieve entries from a feed. See EntriesPagination#feed_entries

  def feed_entries(feed, include_read: false, page: nil)
    EntriesPagination.feed_entries feed, self, include_read: include_read, page: page
  end

  ##
  # Retrieve unread entries from a folder. See EntriesPagination#folder_entries

  def folder_entries(folder, include_read: false, page: nil)
    EntriesPagination.folder_entries folder, self, include_read: include_read, page: page
  end

  ##
  # Retrieve the number of unread entries in a feed for this user.
  # See SubscriptionsManager#unread_feed_entries_count

  def feed_unread_count(feed)
    SubscriptionsManager.feed_unread_count feed, self
  end

  ##
  # Move a feed to a folder. See FolderManager#move_feed_to_folder

  def move_feed_to_folder(feed, folder: nil, folder_title: nil)
    FolderManager.move_feed_to_folder feed, self, folder: folder, folder_title: folder_title
  end

  ##
  # Refresh a single feed. See FeedRefreshManager#refresh

  def refresh_feed(feed)
    FeedRefreshManager.refresh feed, self
  end

  ##
  # Find a refresh_feed_job_state belonging to the user

  def find_refresh_feed_job_state(job_id)
    return self.refresh_feed_job_states.find job_id
  end

  ##
  # Subscribe to a feed. See URLSubscriber#subscribe

  def subscribe(url)
    subscribed_feed = URLSubscriber.subscribe url, self
  end

  ##
  # Find a subscribe_job_state belonging to the user

  def find_subscribe_job_state(job_id)
    return self.subscribe_job_states.find job_id
  end

  ##
  # Enqueue a job to subscribe to a feed. See URLSubscriber#enqueue_subscribe_job

  def enqueue_subscribe_job(url)
    URLSubscriber.enqueue_subscribe_job url, self
  end

  ##
  # Unsubscribe from a feed. See FeedUnsubscriber#unsubscribe

  def unsubscribe(feed)
    SubscriptionsManager.remove_subscription feed, self
  end

  ##
  # Enqueue a job to unsubscribe from a feed. See URLSubscriber#enqueue_unsubscribe_job

  def enqueue_unsubscribe_job(feed)
    SubscriptionsManager.enqueue_unsubscribe_job feed, self
  end

  ##
  # Change the read/unread state of entries for this user. See EntryStateManager#change_entries_state

  def change_entries_state(entry, state, whole_feed: false, whole_folder: false, all_entries: false)
    EntryStateManager.change_entries_state entry, state, self, whole_feed: whole_feed, whole_folder: whole_folder, all_entries: all_entries
  end

  ##
  # Import an OPML (optionally zipped) with subscription data, and subscribe the user to the feeds
  # in it. See OPMLImporter#enqueue_import_job

  def import_subscriptions(file)
    OPMLImporter.enqueue_import_job file, self
  end

  ##
  # Export an OPML file with the user's subscriptions.
  # See OPMLExporter#enqueue_export_job

  def export_subscriptions
    OPMLExporter.enqueue_export_job self
  end

  ##
  # Get a previously exported OPML file.
  # See OPMLExporter.get_export

  def get_opml_export
    OPMLExporter.get_export self
  end

  ##
  # Change the visibility of the alert related to the OPML import state.
  # Receives a boolean argument and sets the alert to visible (if true) or hidden (if false).

  def set_opml_import_job_state_visible(visible)
    self.opml_import_job_state.update show_alert: visible
  end

  ##
  # Change the visibility of the alert related to the OPML export state.
  # Receives a boolean argument and sets the alert to visible (if true) or hidden (if false).

  def set_opml_export_job_state_visible(visible)
    self.opml_export_job_state.update show_alert: visible
  end

  ##
  # Immediately lock the user account so that it cannot log in. Enqueue a job to destroy
  # the user.
  def delete_profile
    self.lock_access! send_instructions: false
    DestroyUserWorker.perform_async self.id
  end

  ##
  # Update the user configuration.
  # Receives as optional named arguments the supported config values that can be set:
  # - show_main_tour (boolean): whether to show the main application tour
  # - show_mobile_tour (boolean): whether to show the mobile application tour
  # - show_feed_tour (boolean): whether to show the feed application tour
  # - show_entry_tour (boolean): whether to show the entry application tour

  def update_config(show_main_tour: nil, show_mobile_tour: nil, show_feed_tour: nil, show_entry_tour: nil)
    new_config = {}
    new_config[:show_main_tour] = show_main_tour if !show_main_tour.nil?
    new_config[:show_mobile_tour] = show_mobile_tour if !show_mobile_tour.nil?
    new_config[:show_feed_tour] = show_feed_tour if !show_feed_tour.nil?
    new_config[:show_entry_tour] = show_entry_tour if !show_entry_tour.nil?
    Rails.logger.info "Updating user #{self.id} - #{self.email} with show_main_tour #{show_main_tour}, " +
                          "show_mobile_tour #{show_mobile_tour}, show_feed_tour #{show_feed_tour}, " +
                          "show_entry_tour #{show_entry_tour}"
    self.update new_config if new_config.length > 0
  end

  private

  ##
  # Operations necessary before saving a User in the database:
  # - ensure that the encrypted_password is encoded as utf-8
  # - create a new OpmlImportJobState instance for the user with state "NONE" if it doesn't already exist (to indicate that
  # the user has never ran an OPML import).
  # - create a new OpmlExportJobState instance for the user with state "NONE" if it doesn't already exist (to indicate that
  # the user has never ran an OPML export).

  def before_save_user
    self.encrypted_password.encode! 'utf-8'

    if self.opml_import_job_state.blank?
      self.create_opml_import_job_state state: OpmlImportJobState::NONE
      Rails.logger.debug "User #{self.email} has no OpmlImportJobState, creating one with state NONE"
    end

    if self.opml_export_job_state.blank?
      self.create_opml_export_job_state state: OpmlExportJobState::NONE
      Rails.logger.debug "User #{self.email} has no OpmlExportJobState, creating one with state NONE"
    end

    # If demo is enabled, demo user cannot change email or password nor be locked
    if Feedbunch::Application.config.demo_enabled
      demo_email = Feedbunch::Application.config.demo_email
      if email_changed? && self.email_was == demo_email
        Rails.logger.info 'Somebody attempted to change the demo user email. Blocking the attempt.'
        self.errors.add :email, 'Cannot change demo user email'
        self.email = demo_email
      end

      demo_password = Feedbunch::Application.config.demo_password
      if encrypted_password_changed? && self.email == demo_email
        Rails.logger.info 'Somebody attempted to change the demo user password. Blocking the attempt.'
        self.errors.add :password, 'Cannot change demo user password'
        self.password = demo_password
      end

      if locked_at_changed? && self.email == demo_email
        Rails.logger.info 'Keeping demo user from being locked because of too many authentication failures'
        self.locked_at = nil
      end

      if unlock_token_changed? && self.email == demo_email
        Rails.logger.info 'Removing unlock token for demo user, demo user cannot be locked out'
        self.unlock_token = nil
      end
    end
  end

  ##
  # Operations after saving a user in the db:
  # - update the config_updated_at attribute to the current datetime if one of these attributes has changed value:
  #   - quick_reading
  #   - open_all_entries
  #   - show_main_tour
  #   - show_mobile_tour
  #   - show_feed_tour
  #   - show_entry_tour

  def after_save_user
    if quick_reading_changed? || open_all_entries_changed? ||
        show_main_tour_changed? || show_mobile_tour_changed? ||
        show_feed_tour_changed? || show_entry_tour_changed?
      update_column :config_updated_at, Time.zone.now
    end
  end

  ##
  # Give the following default values to the user, in case no value or an invalid value is set:
  # - locale: 'en'
  # - timezone: 'UTC'
  # - admin: false
  # - free: false
  # - quick_reading: false
  # - open_all_entries: false
  # - show_main_tour, show_mobile_tour, show_feed_tour: show_entry_tour: true
  # - name: defaults to the value of the "email" attribute
  # - invitation_limit: the value configured in Feedbunch::Application.config.daily_invitations_limit (in config/application.rb)
  # - subscriptions_updated_at: current date/time
  # - first_confirmation_reminder_sent, second_confirmation_reminder_sent: false

  def default_values
    # Convert the symbols for the available locales to strings, to be able to compare with the user locale
    # NOTE.- don't do the opposite (converting the user locale to a symbol before checking if it's included in the
    # array of available locales) because memory allocated for symbols is never released by ruby, which means an
    # attacker could cause a memory leak by creating users with weird unavailable locales.
    available_locales = I18n.available_locales.map {|l| l.to_s}
    if !available_locales.include? self.locale
      Rails.logger.info "User #{self.email} has unsupported locale #{self.locale}. Defaulting to locale 'en' instead"
      self.locale = 'en'
    end

    timezone_names = ActiveSupport::TimeZone.all.map{|tz| tz.name}
    if !timezone_names.include? self.timezone
      Rails.logger.info "User #{self.email} has unsupported timezone #{self.timezone}. Defaulting to timezone 'UTC' instead"
      self.timezone = 'UTC'
    end

    if self.admin == nil
      Rails.logger.info "User #{self.email} has unsupported admin #{self.admin}. Defaulting to admin 'false' instead"
      self.admin = false
    end

    if self.free == nil
      Rails.logger.info "User #{self.email} has unsupported free #{self.free}. Defaulting to free 'false' instead"
      self.free = false
    end

    if self.quick_reading == nil
      Rails.logger.info "User #{self.email} has unsupported quick_reading #{self.quick_reading}. Defaulting to quick_reading 'false' instead"
      self.quick_reading = false
    end

    if self.open_all_entries == nil
      Rails.logger.info "User #{self.email} has unsupported open_all_entries #{self.open_all_entries}. Defaulting to open_all_entries 'false' instead"
      self.open_all_entries = false
    end

    if self.show_main_tour == nil
      Rails.logger.info "User #{self.email} has unsupported show_main_tour #{self.show_main_tour}. Defaulting to show_main_tour 'true' instead"
      self.show_main_tour = true
    end

    if self.show_mobile_tour == nil
      Rails.logger.info "User #{self.email} has unsupported show_mobile_tour #{self.show_mobile_tour}. Defaulting to show_mobile_tour 'true' instead"
      self.show_mobile_tour = true
    end

    if self.show_feed_tour == nil
      Rails.logger.info "User #{self.email} has unsupported show_feed_tour #{self.show_feed_tour}. Defaulting to show_feed_tour 'true' instead"
      self.show_feed_tour = true
    end

    if self.show_entry_tour == nil
      Rails.logger.info "User #{self.email} has unsupported show_entry_tour #{self.show_entry_tour}. Defaulting to show_entry_tour 'true' instead"
      self.show_entry_tour = true
    end

    if self.name.blank?
      Rails.logger.info "User #{self.email} has no name set. Using the email by default."
      self.name = self.email
    end

    # By default each user has the daily invitations limit set in application.rb
    if self.invitation_limit.blank?
      limit = Feedbunch::Application.config.daily_invitations_limit
      Rails.logger.info "User #{self.email} has no invitation limit set. Using #{limit} by default."
      self.invitation_limit = limit
    end

    if self.subscriptions_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported subscriptions_updated_at value, using current datetime by default"
      self.subscriptions_updated_at = Time.zone.now
    end

    if self.folders_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported folders_updated_at value, using current datetime by default"
      self.folders_updated_at = Time.zone.now
    end

    if self.refresh_feed_jobs_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported refresh_feed_jobs_updated_at value, using current datetime by default"
      self.refresh_feed_jobs_updated_at = Time.zone.now
    end

    if self.subscribe_jobs_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported subscribe_jobs_updated_at value, using current datetime by default"
      self.subscribe_jobs_updated_at = Time.zone.now
    end

    if self.config_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported config_updated_at value, using current datetime by default"
      self.config_updated_at = Time.zone.now
    end

    if self.user_data_updated_at == nil
      Rails.logger.info "User #{self.email} has unsupported user_data_updated_at value, using current datetime by default"
      self.user_data_updated_at = Time.zone.now
    end

    if self.first_confirmation_reminder_sent == nil
      Rails.logger.info "User #{self.email} has unsupported first_confirmation_reminder_sent #{self.first_confirmation_reminder_sent}. Defaulting to 'false' instead"
      self.first_confirmation_reminder_sent = false
    end

    if self.second_confirmation_reminder_sent == nil
      Rails.logger.info "User #{self.email} has unsupported second_confirmation_reminder_sent #{self.second_confirmation_reminder_sent}. Defaulting to 'false' instead"
      self.second_confirmation_reminder_sent = false
    end

    return true
  end

  ##
  # Mark as unread for this user all entries of the feed passed as argument.

  def mark_unread_entries(feed_subscription)
    feed = feed_subscription.feed
    feed.entries.find_each do |entry|
      if !EntryState.exists? user_id: self.id, entry_id: entry.id
        entry_state = self.entry_states.create! entry_id: entry.id, read: false
      end
    end
  end

  ##
  # Before removing a feed subscription:
  # - remove the feed from its current folder, if any. If this means the folder is now empty, a deletion of the folder is triggered.
  # - delete all state information (read/unread) for this user and for all entries of the feed.
  # - delete all instances of RefreshFeedJobState associated with this feed and user.
  # - delete all instances of SubscribeJobState associated with this feed and user.

  def before_remove_feed_subscription(feed_subscription)
    feed = feed_subscription.feed

    folder = feed.user_folder self
    folder.feeds.delete feed if folder.present?

    remove_entry_states feed
    remove_refresh_feed_job_states feed
    remove_subscribe_job_states feed
  end

  ##
  # When a feed is removed from a user's subscriptions, check if there are other users still subscribed to the feed
  # and if there are no subscribed users, delete the feed. This triggers the deletion of all its entries and entry-states.

  def removed_feed_subscription(feed_subscription)
    feed = feed_subscription.feed
    if feed.users.count == 0
      Rails.logger.warn "no more users subscribed to feed #{feed.id} - #{feed.fetch_url} . Removing it from the database"
      feed.destroy
    end
  end

  ##
  # Remove al read/unread entry information for this user, for all entries of the feed passed as argument.

  def remove_entry_states(feed)
    feed.entries.find_each do |entry|
      entry_state = EntryState.find_by user_id: self.id, entry_id: entry.id
      self.entry_states.delete entry_state
    end
  end

  ##
  # Remove al RefreshFeedJobState instances associated with this user and the feed passed as argument

  def remove_refresh_feed_job_states(feed)
    self.refresh_feed_job_states.where(feed_id: feed.id).destroy_all
  end

  ##
  # Remove al SubscribeJobState instances associated with this user and the feed passed as argument

  def remove_subscribe_job_states(feed)
    self.subscribe_job_states.where(feed_id: feed.id).destroy_all
  end

end
