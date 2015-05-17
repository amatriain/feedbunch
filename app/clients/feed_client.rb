require 'feedjira'
require 'rest_client'
require 'restclient/components'
require 'rack/cache'
require 'nokogiri'
require 'uri'
require 'feed_autodiscovery'
require 'feed_parser'

##
# This class can fetch feeds and parse them. It also takes care of caching, sending HTTP headers
# that indicate the server to send only new entries.

class FeedClient

  ##
  # Fetch a feed, parse it and save the entries in the database. This is a class method.
  #
  # Receives as arguments
  # - feed: feed to be fetched. It must already be saved in the database and its fetch_url field must have a value.
  # - http_caching (optional). Boolean indicating if client-side HTTP caching (with rack-cache) will be used.
  # Defaults to true.
  # - perform_autodiscovery (optional). Boolean indicating if feed autodiscovery should be performed on an HTML response.
  # Defaults to false.
  #
  # If HTTP caching is used the response will be retrieved from the local cache if the headers show it is still valid.
  #
  # If the response to the GET is not a feed but an HTML document and the "perform_autodiscovery" argument is
  # true, it tries to autodiscover a feed from the HTML. If a feed is autodiscovered, it is immediately
  # fetched but passing a false to the "perform_autodiscovery" argument, to avoid entering an infinite loop of
  # HTTP GETs.
  #
  # Returns feed instance if fetch is successful, raises an error otherwise.

  def self.fetch(feed, http_caching: true, perform_autodiscovery: false)
    http_response = fetch_valid_feed feed, http_caching, perform_autodiscovery

    if http_response.present?
      feed = handle_html_response feed, http_response, perform_autodiscovery
    end

    return feed
  end

  private

  ##
  # Fetch a feed, parse it and save received entries in the database.
  # This method assumes that the document at feed.fetch_url is a valid feed.
  #
  # Receives as arguments:
  # - feed instance to be fetched
  # - http_caching: boolean indicating whether to use client-side HTTP caching.
  # - perform_autodiscovery: boolean indicating whether autodiscovery will be performed if the response is an HTML
  # document.
  #
  # If the http_caching argument is true, the response will be retrieved from the local cache if the headers indicate
  # that it is still valid. If the response is retrieved from the cache, as indicated by the X-Rack-Cache header,
  # the response won't be processed (no parsing, saving entries etc) because it is assumed that the entries in the
  # response have already been saved in the database.
  #
  # If the perform_autodiscovery argument is true, the url attribute of the feed is used for the HTTP GET (it is the
  # attribute most likely to lead to a webpage) and no HTTP caching headers are sent (we want to get the most up to date
  # version of the page, in case autodiscovery data has changed).
  #
  # If the perform_autodiscovery argument is false the fetch_url attribute of the feed is used for the HTTP GET, and
  # HTTP caching headers (if-none-match, if-modified-since) will be used if possible.
  #
  # If there's a problem downloading from feed.fetch_url, raises an error.
  #
  # If there's a problem parsing the downloaded document (e.g. if the document
  # is HTML instead of a valid feed), returns the HTTP response so that other
  # methods can try to perform feed autodiscovery.
  #
  # If the feed is successfully fetched and parsed, returns nil.

  def self.fetch_valid_feed(feed, http_caching, perform_autodiscovery)
    # User-agent used by feedbunch when fetching feeds
    user_agent = Feedbunch::Application.config.user_agent

    if perform_autodiscovery
      Rails.logger.info "Performing autodiscovery on feed #{feed.id} - URL #{feed.url}"
      url = feed.url
    else
      Rails.logger.info "Fetching feed #{feed.id} - fetch_URL #{feed.fetch_url} without autodiscovery"
      url = feed.fetch_url
    end

    if http_caching
      Rails.logger.info "Fetching feed #{feed.id} - fetch_URL #{feed.fetch_url} using HTTP caching if possible"
      RestClient.enable Rack::Cache,
                        verbose: true,
                        metastore: "file:#{Rails.root.join('rack_cache', 'metastore').to_s}",
                        entitystore: "file:#{Rails.root.join('rack_cache', 'entitystore').to_s}"
    else
      Rails.logger.info "Fetching feed #{feed.id} - fetch_URL #{feed.fetch_url} without HTTP caching"
      RestClient.disable Rack::Cache
    end

    # GET the feed
    Rails.logger.info "Fetching from URL #{url}"

    feed_response = RestClient.get url, user_agent: user_agent

    # If the response was retrieved from the cache, do not process it (entries are already in the db)
    if http_caching
      headers = feed_response.try :headers
      if headers.present?
        x_rack_cache = headers[:x_rack_cache]
        if x_rack_cache.present?
          if x_rack_cache.include?('fresh') || (x_rack_cache.include?('valid') && !x_rack_cache.include?('invalid'))
            Rails.logger.info "Feed #{feed.id} - #{feed.fetch_url} cached response is valid, there are no new entries. Skipping response processing."
            return nil
          end
        end
        end
    end

    # RestClients ignores the HTTP charset and always thinks responses are UTF-8, this must be corrected.
    headers = feed_response.try :headers
    content_type = headers[:content_type] unless headers.blank?
    charset = content_type.to_s[/\bcharset[ ]*=[ '"]*([^ '";]+)['";]*/, 1] unless content_type.blank?
    begin
      if charset.present?
        encoding = Encoding.find charset
      else
        # use utf-8 by default if charset not reported by HTTP content-type
        encoding = Encoding.find 'utf-8'
      end
    rescue ArgumentError
      Rails.logger.warn "Unknown charset #{charset} reported by HTTP content-type header, using utf-8 instead"
      encoding = Encoding.find 'utf-8'
    end

    Rails.logger.info "Detected encoding #{encoding.to_s} for the feed, converting to utf-8 if necessary"
    feed_response.force_encoding encoding unless feed_response.nil?

    # We want the response to end up being UTF-8 because Feedjira handles other encodings poorly.
    feed_response.try :encode!, 'utf-8', {:invalid => :replace, :undef => :replace, :replace => '?'}

    if feed_response.blank?
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
      raise EmptyResponseError.new
    end

    begin
      # Try to parse the response as a feed
      FeedParser.parse feed, feed_response
      return nil
    rescue
      return feed_response
    end
  rescue RestClient::NotModified => e
    Rails.logger.info "Feed #{feed.fetch_url} returned 304 - not modified"
    return nil
  end

  ##
  # Handle an HTTP response assuming it's not a valid feed but probably an HTML document,
  # maybe with feed autodiscovery enabled.
  #
  # Receives as arguments:
  # - the feed instance that is being fetched
  # - the http response that could be an HTML document with feed autodiscovery
  # - a boolean flag that controls whether this method tries to perform feed autodiscovery (if true) or not (if false)
  #
  # If perform_autodiscovery is true, and the HTML document has a feed linked in its head, a new fetch of the linked
  # feed is triggered. However this second fetch will not try to perform feed autodiscovery; this is to avoid the
  # situation in which a webpage links to itself, which could lead to an infinite loop unless the second fetch does not
  # perform feed autodiscovery.
  #
  # If feed autodiscovery does not finish successfully, an error is raised.

  def self.handle_html_response(feed, http_response, perform_autodiscovery)
    if perform_autodiscovery
      # If there was a problem parsing the feed assume we've downloaded an HTML webpage, try to perform feed autodiscovery
      discovered_feed = FeedAutodiscovery.discover feed, http_response
      if discovered_feed.present?
        # If feed autodiscovery is successful, fetch the feed to get its entries, title, url etc.
        # This second fetch will not try to perform autodiscovery, to avoid entering an infinite loop.
        # Also this second fetch will not use a client-side cache, to make sure we don't retrieve a stale
        # response from the cache.
        return FeedClient.fetch discovered_feed, http_caching: false, perform_autodiscovery: false
      else
        raise FeedAutodiscoveryError.new
      end
    else
      Rails.logger.warn "Tried to fetch #{feed.fetch_url} but it is not a valid feed"
      raise FeedFetchError.new
    end
  end


end