require 'feedzirra'
require 'rest_client'

##
# This class can fetch feeds and parse them. It also takes care of caching, sending HTTP headers
# that indicate the server to send only new entries.

class FeedClient
  # Class to be used for feed downloading. It defaults to RestClient.
  # During unit testing it can be switched with a mock object, so that no actual HTTP calls are made.
  attr_writer :http_client

  ##
  # Fetch a feed, parse it and save the entries in the database.
  # It sends if-none-match and if-modified-since HTTP headers to indicate the server to send only new entries.

  def fetch(feed_id)
    feed = Feed.find feed_id

    # http_client defaults to RestClient, except if it's already been given another value (which happens
    # during unit testing, in which a mocked is used instead of the real class)
    http_client = @http_client || RestClient
    Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with etag: #{feed.etag} - last-modified: #{feed.last_modified}"
    headers = {}
    headers[:if_none_match] = feed.etag if feed.etag.present?
    headers[:if_modified_since] = feed.last_modified if feed.last_modified.present?
    feed_response = http_client.get feed.fetch_url, headers

    if feed_response.present?
      # We use the actual Feedzirra::Feed class to parse, never a mock.
      # The motivation behind using a mock for fetching the XML during unit testing is not making HTTP
      # calls during testing, but we can always use the real parser even during testing.
      feed_parsed = Feedzirra::Feed.parse feed_response

      # Save the feed title and url.
      # Warning: don't confuse url (the url of the website generating the feed) with fetch_url (the url from which the
      # XML of the feed is fetched).
      Rails.logger.info "Fetched from: #{feed.fetch_url} - title: #{feed_parsed.title} - url: #{feed_parsed.url}"
      feed.title = feed_parsed.title
      feed.url = feed_parsed.url

      # Save the etag and last_modified headers. If one of these headers is not present, save a null in the database.
      if feed_response.headers.present?
        Rails.logger.info "HTTP headers in the response from #{feed.fetch_url} - etag: #{feed_response.headers[:etag]} - last-modified: #{feed_response.headers[:last_modified]}"
        feed.etag = feed_response.headers[:etag]
        feed.last_modified = feed_response.headers[:last_modified]
      end

      # Save entries in the database
      feed_parsed.entries.each do |f|
        e = Entry.new
        e.title = f.title
        e.url = f.url
        e.author = f.author
        e.content = f.content
        e.summary = f.summary
        e.published = f.published
        e.guid = f.entry_id
        Rails.logger.info "Saving in the database new entry for feed #{feed.fetch_url} - title: #{e.title} - guid: #{e.guid}"
        feed.entries << e
      end

      feed.save

    else
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
    end

    return true
  end
end