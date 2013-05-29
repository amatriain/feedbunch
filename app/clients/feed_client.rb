require 'feedzirra'
require 'rest_client'
require 'nokogiri'
require 'uri'
require 'feed_autodiscovery'
require 'feed_caching'
require 'feed_parser'

##
# This class can fetch feeds and parse them. It also takes care of caching, sending HTTP headers
# that indicate the server to send only new entries.

class FeedClient

  ##
  # Fetch a feed, parse it and save the entries in the database. This is a class method.
  #
  # Receives as argument the id of the feed to fetch. It must already be saved in the database and its
  # fetch_url field must have value.
  #
  # Optionally receives as argument a boolean that tells the method whether to perform feed autodiscovery. It
  # defaults to true.
  #
  # The method tries to use the last received etag with the if-none-match header to indicate the server to send only new
  # entries.
  #
  # If no etag was received last time the feed was fetched, it tries to use the last received last-modified header with the
  # if-modified-since request header to indicate the server to send only new entries.
  #
  # If the last time the feed was fetched no etag and no last-modified headers were in the response, this method fetches
  # the full feed without sending caching headers.
  #
  # If the response to the GET is not a feed but an HTML document and the "perform_autodiscovery" argument is
  # true, it tries to autodiscover a feed from the HTML. If a feed is autodiscovered, it is immediately
  # fetched but passing a false to the "perform_autodiscovery" argument, to avoid entering an infinite loop of
  # HTTP GETs.
  #
  # Returns feed instance if fetch is successful, raises an error otherwise.

  def self.fetch(feed_id, perform_autodiscovery=true)
    feed = Feed.find feed_id
    http_response = fetch_valid_feed feed

    if http_response.present?
      feed = handle_html_response feed, http_response, perform_autodiscovery
    end

    return feed
  end

  ##
  # Fetch a feed, parse it and save received entries in the database.
  # This method assumes that the document at feed.fetch_url is a valid feed.
  #
  # Receives as argument the feed instance to be fetched.
  #
  # If there's a problem downloading from feed.fetch_url, raises an error.
  #
  # If there's a problem parsing the downloaded document (e.g. if the document
  # is HTML instead of a valid feed), returns the HTTP response so that other
  # methods can try to perform feed autodiscovery.
  #
  # If the feed is successfully fetched and parsed, returns nil.

  def self.fetch_valid_feed(feed)
    # Calculate HTTP headers to be used for fetching
    headers = FeedCaching.fetch_headers feed

    # GET the feed
    Rails.logger.info "Fetching from URL #{feed.fetch_url}"
    feed_response = RestClient.get feed.fetch_url, headers

    if feed_response.present?
      begin
        # Try to parse the response as a feed
        FeedParser.parse_feed feed, feed_response
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
      discovered_feed = FeedAutodiscovery.perform_feed_autodiscovery feed, http_response
      if discovered_feed.present?
        # If feed autodiscovery is successful, fetch the feed to get its entries, title, url etc.
        # This second fetch will not try to perform autodiscovery, to avoid entering an infinite loop.
        return FeedClient.fetch discovered_feed.id, false
      else
        raise FeedAutodiscoveryError.new
      end
    else
      Rails.logger.warn "Tried to fetch #{feed.fetch_url} after feed autodiscovery, but the response is not a parseable feed"
      raise FeedAutodiscoveryError.new
    end
  end


end