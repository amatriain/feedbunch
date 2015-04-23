require 'uri'
require 'addressable/uri'
require 'encoding_manager'
require 'schedule_manager'
require 'feed_blacklister'

##
# Feed model. Each instance of this model represents a single feed (Atom, RSS...) to which users can be suscribed.
#
# A single feed can have many subscriptions (from different users), but a single subscription corresponds to a single feed (one-to-many relationship).
#
# Users are associated with Feeds through the FeedSubscription model. This enables us to retrieve users that are subscribed to a feed.
#
# Feeds can be associated with folders. Each feed can be in many folders (as long as they belong to different users),
# and each folder can have many feeds (many-to-many association). However a single feed cannot be associated with
# more than one folder from the same user.
#
# Each feed can have many entries.
#
# Each feed can have many deleted_entries
#
# Each feed can be associated with many refresh_feed_job_states. Each such association represents an ocurrence of a user
# manually requesting a refresh of this feed.
#
# Each feed can be associated with many subscribe_job_states. Each such association represents an occurrence of a user
# successfully subscribing to the feed. They are transient and can be destroyed if the user dismisses the alert that informs
# him of the success subscribing to the feed; but if there is still a FeedSusbscription instance joining user and feed, the user
# is still subscribed to the feed.
#
# Each feed, identified by its fetch_url, can be present at most once in the database. Different feeds can have the same
# title, as long as they have different fetch_url.
#
# Attributes of the model:
# - title
# - fetch_url (URL to fetch the feed XML)
# - last_fetched (timestamp of the last time the feed was fetched, nil if it's never been fetched)
# - fetch_interval_secs (current interval between fetches, in seconds)
# - failing_since (if not null, feed updates have been failing since the datetime  value of this field)
# - available (if false, the feed is permanently unavailable and updates are not scheduled for it)
# - url (URL to which the user will be linked; usually the website that originated this feed)
#
# Title, fetch_url and url are sanitized (with ActionView::Helpers::SanitizeHelper) before validation; this is,
# before saving/updating each instance in the database.

class Feed < ActiveRecord::Base

  has_many :feed_subscriptions, -> {uniq}, dependent: :destroy
  has_many :users, through: :feed_subscriptions
  has_and_belongs_to_many :folders, -> {uniq}, before_add: :single_user_folder
  has_many :entries, -> {uniq}, dependent: :destroy
  has_many :deleted_entries, -> {uniq}, dependent: :destroy
  has_many :refresh_feed_job_states, dependent: :destroy
  has_many :subscribe_job_states, dependent: :destroy

  validates :fetch_url, format: {with: URI::regexp(%w{http https})}, presence: true, uniqueness: {case_sensitive: false}
  validates :url, format: {with: URI::regexp(%w{http https})}, allow_blank: true
  validates :title, presence: true
  validates :fetch_interval_secs, presence: true
  validates :available, inclusion: {in: [true, false]}

  before_validation :before_validation

  after_create :schedule_update
  after_destroy :unschedule_updates
  before_save :unschedule_unavailable
  after_save :touch_subscriptions

  ##
  # Find the folder to which a feed belongs, for a given user.
  #
  # Receives as argument a user.
  #
  # A feed can belong to many folders that belong to many users, but only to a single folder for a given user.
  # This method searches among the folders to which this feed belongs, trying to find one that belongs to the
  # user passed as argument.
  #
  # If a matching folder is found, it is returned. Otherwise nil is returned.

  def user_folder(user)
    folder = self.folders.find_by user_id: user.id
    return folder
  end

  ##
  # Remove this feed from its current folder, if any, for a given user.
  #
  # Receives as argument a user.
  #
  # A feed can only be in a single folder owned by a given user, so it's not necessary to pass the folder id
  # as an argument, it can be inferred from the user id and feed id.
  #
  # If the feed is in a folder owned by the passed user, it is removed from the folder.
  # Otherwise nothing is done.
  #
  # Returns a Folder instance with the data of the folder in which the feed was previously, or nil
  # if it wasn't in any folder. This object may have already  been deleted from the database,
  # if there were no more feeds in it.

  def remove_from_folder(user)
    folder = self.user_folder user
    if folder.present?
      Rails.logger.info "user #{user.id} - #{user.email} is removing feed #{self.id} - #{self.fetch_url} from folder #{folder.id} - #{folder.title}"
      folder.feeds.delete self
    else
      Rails.logger.info "user #{user.id} - #{user.email} is trying to remove feed #{self.id} - #{self.fetch_url} from its folder, but it's not in any folder"
    end

    return folder
  end

  ##
  # Check if a feed exists in the database matching a given URL. This is a class method.
  #
  # Receives as argument a URL.
  #
  # It checks several variants of the passed URL to see if there's a matching feed:
  #
  # - First it checks with the passed URL as-is.
  # - If the passed URL has a trailing slash, it checks with the slash removed.
  # - If the passed URL does not have a trailing slash, it checks with an added trailing slash.
  #
  # In all three cases it invokes the Feed.url_feed method to check if there's a matching feed.
  #
  # If a matching feed is found, it is returned. Otherwise returns nil.

  def self.url_variants_feed(feed_url)
    # Ensure that the passed url has an http:/// or https:// uri-scheme
    url = URLNormalizer.normalize_feed_url feed_url
    # Remove leading and trailing whitespace, to avoid confusion when detecting trailing slashes
    stripped_url = url.strip
    Rails.logger.info "Searching for matching feeds for url #{stripped_url}"
    matching_feed = Feed.url_feed stripped_url
    if matching_feed.blank? && stripped_url =~ /.*[^\/]$/
      Rails.logger.info "No matching feed found for #{stripped_url}, adding trailing slash to search again for url"
      url_slash = stripped_url + '/'
      matching_feed = Feed.url_feed url_slash
    elsif matching_feed.blank? && stripped_url =~ /.*\/$/
      Rails.logger.info "No matching feed found for #{stripped_url}, removing trailing slash to search again for url"
      url_no_slash = stripped_url.chop
      matching_feed = Feed.url_feed url_no_slash
    end

    return matching_feed
  end

  private

  ##
  # After saving a new feed in the database, a scheduled job will be created to update it periodically

  def schedule_update
    ScheduleManager.schedule_first_update self.id
  end

  ##
  # After removing a feed from the database, the scheduled job that updated it will be unscheduled.

  def unschedule_updates
    ScheduleManager.unschedule_feed_updates self.id
  end

  ##
  # If the available attribute is set to false, unschedule the job that updates this feed

  def unschedule_unavailable
    if !self.available && self.available_changed?
      ScheduleManager.unschedule_feed_updates self.id
    end
  end

  ##
  # Touch (update the updated_at attribute) associated subscriptions if at least one of these attributes has changed:
  # - title
  # - url
  # The subscriptions_updated_at of subscribed users is also updated to the current date and time
  #
  # This is meant to invalidate the HTTP cache and force clients to download this feed again.

  def touch_subscriptions
    if title_changed? || url_changed?
      feed_subscriptions.find_each do |s|
        s.touch_subscriptions
      end
    end
  end

  ##
  # Before adding a feed to a folder, ensure that the feed is not already in other folders that belong
  # to the same user. In this case, raise a rollback error.

  def single_user_folder(folder)
    if self.folders.present?
      raise ActiveRecord::Rollback if self.folders.where(user_id: folder.user_id).exists?
    end
  end

  ##
  # Various operations before each validation:
  # - fix any encoding problems, converting to utf-8 if necessary
  # - set default values for missing attributes
  # - sanitize values, removing script tags from entry bodies etc.
  # - encode any invalid characters in url and fetch_url
  # - check if the feed url or fetch_url is blacklisted, and if so a BlacklistedUrlError is raised

  def before_validation
    fix_encoding
    default_values
    sanitize_attributes
    fix_urls
    check_if_blacklisted
  end

  ##
  # Fix problems with encoding in text attributes.
  # Specifically, convert from ISO-8859-1 to UTF-8 if necessary.

  def fix_encoding
    self.title = EncodingManager.fix_encoding self.title
    self.url = EncodingManager.fix_encoding self.url
    self.fetch_url = EncodingManager.fix_encoding self.fetch_url
  end

  ##
  # Give default values to attributes:
  # - fetch_interval_secs defaults to 3600 seconds (1 hour)
  # - available defaults to true

  def default_values
    self.url = self.fetch_url if self.url.blank?
    self.fetch_interval_secs = 3600 if self.fetch_interval_secs.blank?
    self.available = true if self.available.nil?
  end

  ##
  # Sanitize and trim the title, URL and fetch URL of the feed.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!
  #
  # Also, if an update tries to set a value for url or fetch_url which is not a valid URL, ignore
  # the update only for that attribute and keep the old value.

  def sanitize_attributes
    config = Feedbunch::Application.config.restricted_sanitizer

    self.title = Sanitize.fragment(self.title, config).try :strip

    # Unescape HTML entities in the URL escaped by the sanitizer
    self.fetch_url = CGI.unescapeHTML(Sanitize.fragment(self.fetch_url, config).try :strip)
    self.url = CGI.unescapeHTML(Sanitize.fragment(self.url, config).try :strip)

    # URLs must be valid http or https
    if self.fetch_url_was.present? && (self.fetch_url =~ URI::regexp(%w{http https})).nil?
      self.fetch_url = self.fetch_url_was
    end

    if self.url_was.present? && (self.url =~ URI::regexp(%w{http https})).nil?
      self.url = self.url_was
    end

    # Title must not become blank because of sanitization
    if self.title.blank? && self.title_was.present?
      Rails.logger.debug "Feed #{id} title '#{title_was}' would have become blank because of sanitization. Keeping the old value instead."
      self.title = self.title_was
    end
  end

  ##
  # Fix problems with URLs, by URL-encoding any illegal characters.

  def fix_urls
    self.url = URLNormalizer.normalize_feed_url self.url if self.url.present?
    self.fetch_url = URLNormalizer.normalize_feed_url self.fetch_url if self.fetch_url.present?
  end

  ##
  # Check if the feed's url or fetch_url is blacklisted.
  #
  # If it is blacklisted, a BlacklistedUrlError is raised. Otherwise returns nil.

  def check_if_blacklisted
    raise BlacklistedUrlError.new if FeedBlacklister.blacklisted_feed? self
    return nil
  end

  ##
  # Check if a feed exists in the database with a given a URL. This is a class method.
  #
  # Receives as argument a URL.
  #
  # If there is a feed in the database which "url" or "fetch_url" field matches with
  # the url passed as argument, returns the feed object; returns nil otherwise.

  def self.url_feed(url)
    if Feed.exists? fetch_url: url
      Rails.logger.info "Feed with fetch_url #{url} already exists in the database"
      return Feed.find_by fetch_url: url
    elsif Feed.exists? url: url
      Rails.logger.info "Feed with url #{url} already exists in the database"
      return Feed.find_by url: url
    else
      Rails.logger.info "Feed #{url} does not exist in the database"
      return nil
    end
  end

end
