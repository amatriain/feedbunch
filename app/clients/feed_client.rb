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

    unless http_response.nil?
      feed = handle_html_response feed, http_response, perform_autodiscovery
    end

    return feed
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

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
    if perform_autodiscovery
      Rails.logger.info "Performing autodiscovery on feed #{feed.id} - URL #{feed.url}"
      url = feed.url
    else
      Rails.logger.info "Fetching feed #{feed.id} - fetch_URL #{feed.fetch_url} without autodiscovery"
      url = feed.fetch_url
    end

    # Use a special class for fetching this particular feed if configured; otherwise use the default HTTP client
    special_fetcher = SpecialFeedManager.get_special_fetcher feed
    if special_fetcher.present?
      feed_response = special_fetcher.fetch_feed url
    else
      feed_response = default_fetch url, http_caching
    end

    # If the response was retrieved from the cache, do not process it (entries are already in the db)
    if http_caching
      headers = feed_response&.headers
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

    feed_response = fix_encoding feed_response

    if feed_response.nil? || feed_response&.size == 0
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
      raise EmptyResponseError.new
    end

    begin
      # Try to parse the response as a feed
      FeedParser.parse feed, feed_response, feed_response.encoding
      return nil
    rescue
      return feed_response
    end
  rescue RestClient::NotModified => e
    Rails.logger.info "Feed #{feed.fetch_url} returned 304 - not modified"
    return nil
  end
  private_class_method :fetch_valid_feed

  ##
  # Default fetching of a URL. Attempts to fetch it with a simple HTTP client (RestClient). If this fails because
  # the URL is behind CloudFlare's DDoS protection, retry with a full headless browser.
  #
  # Receives as arguments:
  # - url to fetch
  # - http_caching: boolean indicating whether to use client-side HTTP caching.
  #
  # Returns a RestClient::Response object with the response, which may be the feed XML or an HTML document that
  # will be handled by other methods. It also may have response headers that give information about caching.

  def self.default_fetch(url, http_caching)
    if http_caching
      Rails.logger.info "Fetching URL #{url} using HTTP caching if possible"
      RestClient.enable Rack::Cache,
                        verbose: false,
                        metastore: "file:#{Rails.root.join('rack_cache', 'metastore').to_s}",
                        entitystore: "file:#{Rails.root.join('rack_cache', 'entitystore').to_s}"
    else
      Rails.logger.info "Fetching URL #{url} without HTTP caching"
      RestClient.disable Rack::Cache
    end

    # User-agent used by RestClient when fetching feeds
    user_agent = Feedbunch::Application.config.user_agent

    begin
      # try to GET the feed with a simple HTTP client (js not enabled)
      Rails.logger.info "Fetching from URL #{url}"
      feed_response = RestClient.get url, user_agent: user_agent
    rescue RestClient::ServiceUnavailable => e
      # try to overcome Cloudflare DDoS protection with a full-featured headless browser
      # Cloudflare sends a 503 error but with a js in the page that after a delay redirects to the actual requested page
      if e.http_code == 503 && e.response.match?(/Cloudflare/i)
        begin
          Rails.logger.info "URL #{url} is behind Cloudflare DDoS protection, using a full browser to fetch it"
          opts = Selenium::WebDriver::Chrome::Options.new
          opts.add_argument '--headless'
          browser = Selenium::WebDriver.for :chrome, options: opts
          browser.get url
          wait = Selenium::WebDriver::Wait.new timeout: 20
          wait.until {
            # wait until the page in the browser is an RSS or Atom feed, or a timeout happens
            browser.find_element :xpath, '//rss|//feed'
          }
          feed_response = browser.page_source
          # some methods necessary later, to emulate a RestClient response
          feed_response.define_singleton_method :headers do
            return []
          end
        rescue Selenium::WebDriver::Error::TimeOutError => eTimeout
          Rails.logger.info "Cannot access URL #{url} behind Cloudflare DDoS protection even with a full browser"
          # if after all the full browser cannot get the feed, raise the original error returned to RestClient
          raise e
        ensure
          # close browser explicitly, otherwise it stays running even after worker stops
          browser.quit
        end
      else
        # if a HTTP 503 error is received but the page is not a Cloudflare DDoS protection page, raise the error as usual
        raise e
      end
    end

    return feed_response
  end
  private_class_method :default_fetch

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
  private_class_method :handle_html_response

  ##
  # Set the correct encoding of the feed string.
  #
  # The actual encoding of the response is detected with this algorithm:
  # - if the HTTP content-type header reports a charset, that encoding is assumed. Otherwise utf-8 is assumed.
  # - the response body is checked to see if the above encoding is valid. If it isn't, the XML is parsed to read the
  # encoding reported in the xml (this may happen for feeds that do not report an encoding in the content-type header
  # but rather report a non-utf8 encoding in the <xml encoding="..."> attribute).
  #
  # Once the actual encoding is determined, the encoding is forced so Ruby is aware of it without changing the string
  # internal representation, and it is returned.
  #
  # Returns nil if a nil string is passed.

  def self.fix_encoding(feed_response)
    return nil if feed_response.nil?

    # Detect encoding from HTTP content-type header, in case RestClient has detected the wrong encoding
    headers = feed_response&.headers
    content_type = headers[:content_type] unless headers.blank?
    charset_http = content_type.to_s[/\bcharset[ ]*=[ '"]*([^ '";]+)['";]*/, 1] unless content_type.blank?

    encoding = find_encoding charset_http
    feed_response.force_encoding encoding

    unless feed_response.valid_encoding?
      Rails.logger.info "Encoding #{encoding.to_s} detected from HTTP headers is not valid, parsing XML to read encoding"
      begin
        parsed_feed = Ox.parse feed_response
        encoding_xml = parsed_feed.encoding
      rescue
        Rails.logger.info 'Could not determine encoding from XML'
        encoding_xml = nil
      end

      encoding = find_encoding encoding_xml
      feed_response.force_encoding encoding
    end

    # We want the response to end up being UTF-8 for convenience
    Rails.logger.info "Detected encoding #{encoding.to_s} for the feed"

    return feed_response
  end
  private_class_method :fix_encoding

  ##
  # Returns a ruby Encoding instance for the passed string.
  # If the passed string is not a valid encoding, an Encoding instance for UTF-8 is returned by default.

  def self.find_encoding(charset)
    begin
      if charset.present?
        encoding = Encoding.find charset
      else
        # use utf-8 by default if a nil is passed
        Rails.logger.info 'No encoding could be determined, using utf-8 by default'
        encoding = Encoding.find 'utf-8'
      end
    rescue ArgumentError
      Rails.logger.warn "Unknown charset #{charset}, using utf-8 instead"
      encoding = Encoding.find 'utf-8'
    end

    return encoding
  end
  private_class_method :find_encoding
end