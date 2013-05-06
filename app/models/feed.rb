require 'uri'

##
# Feed model. Each instance of this model represents a single feed (Atom, RSS...) to which a user is suscribed.
#
# Many users can be suscribed to a single feed, and a single user can be suscribed to many feeds (many-to-many
# relationship).
#
# Each user can have many entries.
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

  has_and_belongs_to_many :users
  has_and_belongs_to_many :folders
  has_many :entries, dependent: :destroy

  validates :fetch_url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, allow_blank: true
  validates :title, presence: true

  before_validation :sanitize_fields

  ##
  # Subscribe a user to a feed. This is a class method.
  #
  # First it checks if the feed is already in the database. If so, the user is subscribed to the feed.
  #
  # Otherwise, it checks if the feed can be fetched. If so, the feed is fetched, saved in the database
  # and the user is subscribed to it.
  #
  # Otherwise, it checks if the URL corresponds to a web page with a feed linked in the header. In this
  # case the feed is fetched, saved in the database and the user subscribed to it.
  #
  # If the end result is that the user is suscribed to a new feed, returns the feed object.
  # Otherwise returns false.

  def self.subscribe(url, user_id)
    Rails.logger.info "User #{user_id} submitted Subscribe form with value #{url}"
    # Ensure the url has a schema (defaults to http:// if none is passed)
    feed_url = ensure_schema url

    user = User.find user_id

    # Check if there is a feed with that URL already in the database
    known_feed = Feed.url_feed feed_url
    if known_feed.present?
      Rails.logger.info "Subscribing user #{user_id} (#{user.email}) to pre-existing feed #{known_feed.id} - #{known_feed.fetch_url}"
      user.feeds << known_feed
      return known_feed
    else
      Rails.logger.info "Feed #{feed_url} not in the database, trying to fetch it"
      feed = Feed.create! fetch_url: feed_url, title: feed_url
      fetch_result = FeedClient.fetch feed.id
      if fetch_result
        Rails.logger.info "New feed #{feed_url} successfully fetched. Subscribing user #{user_id}"
        # We have to reload the feed because the title has likely changed value to the real one when first fetching it
        feed.reload
        user.feeds << feed
        return feed
      else
        Rails.logger.info "URL #{feed_url} is not a valid feed URL"
        feed.destroy
        return false
      end
    end

  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    return false
  end

  ##
  # Ensure that the URL passed as argument has an http:// or https://schema. This is a class method.
  #
  # Receives as argument an URL.
  #
  # If the URL has no schema it is returned prepended with http://
  #
  # If the URL has an http:// or https:// schema, it is returned untouched.

  def self.ensure_schema(url)
    uri = URI.parse url
    if !uri.kind_of?(URI::HTTP) && !uri.kind_of?(URI::HTTPS)
      Rails.logger.info "Value #{url} has no URI scheme, trying to add http:// scheme"
      fixed_url = URI::HTTP.new('http', nil, url, nil, nil, nil, nil, nil, nil).to_s
    else
      fixed_url = url
    end
    return fixed_url
  end

  private

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
