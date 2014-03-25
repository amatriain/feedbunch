require 'uri'
require 'addressable/uri'
require 'encoding_manager'
require 'schedule_manager'

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
# - etag (etag http header received last time the feed was fetched, used for caching)
# - last_modified (last-modified http header received last time the feed was fetched, user for caching)
#
# Title, fetch_url and url are sanitized (with ActionView::Helpers::SanitizeHelper) before validation; this is,
# before saving/updating each instance in the database.

class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  has_many :feed_subscriptions, -> {uniq}, dependent: :destroy
  has_many :users, through: :feed_subscriptions
  has_and_belongs_to_many :folders, -> {uniq}, before_add: :single_user_folder
  has_many :entries, -> {uniq}, dependent: :destroy

  validates :fetch_url, format: {with: URI::regexp(%w{http https})}, presence: true, uniqueness: {case_sensitive: false}
  validates :url, format: {with: URI::regexp(%w{http https})}, allow_blank: true
  validates :title, presence: true
  validates :fetch_interval_secs, presence: true
  validates :available, inclusion: {in: [true, false]}

  before_validation :fix_attributes

  after_create :schedule_updates
  after_destroy :unschedule_updates
  before_save :unschedule_unavailable

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
    if self.folders.exists? user_id: user.id
      folders = self.folders.where(user_id: user.id)
      if folders.present?
        folder = folders.first
      end
    end

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

  def self.url_variants_feed(url)
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

  def schedule_updates
    ScheduleManager.schedule_feed_updates self.id
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
  # Before adding a feed to a folder, ensure that the feed is not already in other folders that belong
  # to the same user. In this case, raise a rollback error.

  def single_user_folder(folder)
    if self.folders.present?
      raise ActiveRecord::Rollback if self.folders.where(user_id: folder.user_id).exists?
    end
  end

  ##
  # Fix any problems with attribute values before validation:
  # - fix any encoding problems, converting to utf-8 if necessary
  # - sanitize values, removing script tags from entry bodies etc.

  def fix_attributes
    default_values
    fix_encoding
    sanitize_attributes
    fix_urls
  end

  ##
  # Give default values to attributes:
  # - fetch_interval_secs defaults to 3600 seconds (1 hour)
  # - available defaults to true

  def default_values
    self.fetch_interval_secs = 3600 if self.fetch_interval_secs.blank?
    self.available = true if self.available.nil?
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
  # Sanitize and trim the title, URL and fetch URL of the feed.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!
  #
  # Also, if an update tries to set a value for url or fetch_url which is not a valid URL, ignore
  # the update only for that attribute and keep the old value.

  def sanitize_attributes
    self.title = sanitize(self.title).try :strip
    self.fetch_url = sanitize(self.fetch_url).try :strip
    self.url = sanitize(self.url).try :strip

    self.fetch_url = self.fetch_url_was if (self.fetch_url =~ URI::regexp(%w{http https})).nil?
    self.url = self.url_was if (self.url =~ URI::regexp(%w{http https})).nil?
  end

  ##
  # Fix problems with URLs, by URL-encoding any illegal characters.

  def fix_urls
    self.url = Addressable::URI.parse(self.url.to_str).display_uri.to_s if self.url.present?
    self.fetch_url = Addressable::URI.parse(self.fetch_url.to_str).display_uri.to_s if self.fetch_url.present?
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
      return Feed.where(fetch_url: url).first
    elsif Feed.exists? url: url
      Rails.logger.info "Feed with url #{url} already exists in the database"
      return Feed.where(url: url).first
    else
      Rails.logger.info "Feed #{url} does not exist in the database"
      return nil
    end
  end

end
