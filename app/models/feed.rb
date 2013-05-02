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

  def self.subscribe(feed_url, user_id)
    Rails.logger.info "User #{user_id} submitted Subscribe form with value #{feed_url}"
    # Check if the argument passed is actually a URI
    uri = URI.parse feed_url
    if !uri.kind_of? URI::HTTP
      Rails.logger.info "Value #{feed_url} submitted by user #{user_id} is not a valid URL"
      return false
    end

    if Feed.exists? fetch_url: feed_url
      Rails.logger.info "Feed #{feed_url} already in the database"
      feed = Feed.where(fetch_url: feed_url).first
      user = User.find user_id
      Rails.logger.info "Subscribing user #{user_id} (#{user.email}) to feed #{feed_url}"
      user.feeds << feed
      return feed
    else
      Rails.logger.info "Feed #{feed_url} not in the database, trying to fetch it"
      feed = Feed.create! fetch_url: feed_url, title: feed_url
      fetch_result = FeedClient.fetch feed.id
      if fetch_result
        Rails.logger.info "New feed #{feed_url} successfully fetched. Subscribing user #{user_id}"
        user = User.find user_id
        user.feeds << feed
        return feed
      else
        Rails.logger.info "URL #{feed_url} is not a valid feed URL"
        feed.destroy
        return false
      end
    end

  rescue URI::InvalidURIError => e
    return false
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
end
