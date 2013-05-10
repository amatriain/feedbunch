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

  ##
  # Subscribe a user to a feed. This is a class method.
  #
  # First it checks if the feed is already in the database. In this case:
  #
  # - If the user is already subscribed to the feed, an AlreadySubscribedError is raised.
  # - Otherwise, the user is subscribed to the feed. The feed is not fetched (it is assumed its entries are
  # fresh enough).
  #
  # If the feed is not in the database, it checks if the feed can be fetched. If so, the feed is fetched,
  # parsed, saved in the database and the user is subscribed to it.
  #
  # If parsing the fetched response fails, it checks if the URL corresponds to an HTML page with feed autodiscovery
  # enabled. In this case the actual feed is fetched, saved in the database and the user subscribed to it.
  #
  # If the end result is that the user has a new subscription, returns the feed object.
  # If the user is already subscribed to the feed, raises an AlreadySubscribedError.
  # Otherwise returns false.
  #
  # Note,- When searching for feeds in the database (to see if there is a feed with a matching URL, and whether the
  # user is already subscribed to it), this method is insensitive to trailing slashes, and if no URI-scheme is
  # present an "http://" scheme is assumed.
  #
  # E.g. if the user is subscribed to a feed with url "\http://xkcd.com/", the following URLs would cause an
  # AlreadySubscribedError to be raised:
  #
  # - "\http://xkcd.com/"
  # - "\http://xkcd.com"
  # - "\xkcd.com/"
  # - "\xkcd.com"

  def self.subscribe(url, user_id)
    Rails.logger.info "User #{user_id} submitted Subscribe form with value #{url}"

    # Ensure the url has a schema (defaults to http:// if none is passed)
    feed_url = ensure_schema url

    user = User.find user_id

    # Check if there is a feed with that URL already in the database
    known_feed = Feed.url_variants_feed feed_url
    if known_feed.present?
      # Check if the user is already subscribed to the feed
      if user.feeds.include? known_feed
        Rails.logger.info "User #{user_id} (#{user.email}) is already subscribed to feed #{known_feed.id} - #{known_feed.fetch_url}"
        raise AlreadySubscribedError.new
      end
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

  rescue AlreadySubscribedError => e
    # AlreadySubscribedError is re-raised to be handled in the controller
    raise e
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    return false
  end

  ##
  # Unsubscribes a user from a feed. This is a class method.
  #
  # Receives as arguments the id of the feed to unsubscribe, and the id of the user doing the unsuscribing.
  #
  # Returns true if succesfully unsuscribed, false otherwise.

  def self.unsubscribe(feed_id, user_id)
    user = User.find user_id
    feed = user.feeds.find feed_id

    Rails.logger.info "unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.fetch_url}"
    user.feeds.delete feed

    if feed.users.blank?
      Rails.logger.warn "no more users subscribed to feed #{feed.id} - #{feed.fetch_url} . Removing it from the database"
      feed.destroy
    end

    return true
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    return false
  end

  ##
  # Find the id of the folder to which a feed belongs, for a given user.
  #
  # Receives as argument a user.
  #
  # A feed can belong to many folders that belong to many users, but only to a single folder for a given user.
  # This method searches among the folders to which this feed belongs, trying to find one that belongs to the
  # user passed as argument.
  #
  # If a matching folder is found, its id is returned. Otherwise nil is returned.

  def user_folder(user)
    if self.folders.present?
      folders = self.folders.where(user_id: user.id)
      if folders.present?
        folder_id = folders.first.id
      end
    end

    return folder_id
  end

  private

  ##
  # Before adding a feed to a folder, ensure that the feed is not already in other folders that belong
  # to the same user. In this case, raise a rollback error.

  def single_user_folder(folder)
    if self.folders.present?
      raise ActiveRecord::Rollback if self.folders.where(user_id: folder.user_id).exists?
    end
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
    Rails.logger.info "Searching for mathing feeds for url #{stripped_url}"
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
