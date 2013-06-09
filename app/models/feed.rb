require 'uri'

##
# Feed model. Each instance of this model represents a single feed (Atom, RSS...) to which a user is suscribed.
#
# Many users can be suscribed to a single feed, and a single user can be suscribed to many feeds (many-to-many
# relationship).
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
# - url (URL to which the user will be linked; usually the website that originated this feed)
# - etag (etag http header received last time the feed was fetched, used for caching)
# - last_modified (last-modified http header received last time the feed was fetched, user for caching)
#
# Both title and fetch_url are mandatory. url and fetch_url are validated with the following regex:
#   /\Ahttps?:\/\/.+\..+\z/
#
# Title, fetch_url and url are sanitized (with ActionView::Helpers::SanitizeHelper) before validation; this is,
# before saving/updating each instance in the database.

class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :fetch_url, :title

  has_and_belongs_to_many :users, uniq: true
  has_and_belongs_to_many :folders, uniq: true, before_add: :single_user_folder
  has_many :entries, dependent: :destroy, uniq: true

  validates :fetch_url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, allow_blank: true
  validates :title, presence: true

  before_validation :sanitize_fields

  after_create :schedule_updates
  after_destroy :unschedule_updates

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
    if self.folders.present?
      folders = self.folders.where(user_id: user.id)
      if folders.present?
        folder = folders.first
      end
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
    UpdateFeedJob.schedule_feed_updates self.id
  end

  ##
  # After removing a feed from the database, the scheduled job that updated it will be unscheduled.

  def unschedule_updates
    UpdateFeedJob.unschedule_feed_updates self.id
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
  # Sanitize the title and URL of the feed.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_fields
    self.title = sanitize self.title
    self.fetch_url = sanitize self.fetch_url
    self.url = sanitize self.url
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
