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
  # Receives as argument the feed to fetch. It must already be saved in the database and its
  # fetch_url field must have value.
  #
  # Optionally receives as argument a boolean that tells the method whether to perform feed autodiscovery. It
  # defaults to false.
  #
  # HTTP caching is used as much as possible (i.e. caching headers are stored and sent so that data is actually sent
  # only if the cached data is no longer valid).
  #
  # If the response to the GET is not a feed but an HTML document and the "perform_autodiscovery" argument is
  # true, it tries to autodiscover a feed from the HTML. If a feed is autodiscovered, it is immediately
  # fetched but passing a false to the "perform_autodiscovery" argument, to avoid entering an infinite loop of
  # HTTP GETs.
  #
  # Returns feed instance if fetch is successful, raises an error otherwise.

  def self.fetch(feed, perform_autodiscovery=false)
    http_response = fetch_valid_feed feed, perform_autodiscovery

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
  # Receives as argument the feed instance to be fetched and a boolean indicating whether to perform feed autodiscovery
  # if necessary.
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

  def self.fetch_valid_feed(feed, perform_autodiscovery)
    if perform_autodiscovery
      Rails.logger.info "Performing autodiscovery on feed #{feed.id} - URL #{feed.url} without HTTP caching"
      url = feed.url
    else
      Rails.logger.info "Fetching feed #{feed.id} - fetch_URL #{feed.fetch_url} without autodiscovery, using HTTP caching if possible"
      url = feed.fetch_url
      RestClient.enable Rack::Cache,
                        verbose: true,
                        metastore: "file:#{Rails.root.join('rack_cache', 'metastore').to_s}",
                        entitystore: "file:#{Rails.root.join('rack_cache', 'entitystore').to_s}"
    end

    # User-agent used by feedbunch when fetching feeds
    user_agent = Feedbunch::Application.config.user_agent

    # GET the feed
    Rails.logger.info "Fetching from URL #{url}"

    feed_response = RestClient.get url, user_agent: user_agent

    # Specify encoding ISO-8859-1 if necessary
    if feed_response.try(:encoding)==Encoding::UTF_8 && !feed_response.try(:valid_encoding?)
      feed_response.force_encoding 'iso-8859-1'
    end

    if feed_response.present?
      begin
        # Try to parse the response as a feed
        FeedParser.parse feed, feed_response
        return nil
      rescue
        return feed_response
      end
    else
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
      raise EmptyResponseError.new
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
        return FeedClient.fetch discovered_feed, false
      else
        raise FeedAutodiscoveryError.new
      end
    else
      Rails.logger.warn "Tried to fetch #{feed.fetch_url} but it is not a valid feed"
      raise FeedFetchError.new
    end
  end


end