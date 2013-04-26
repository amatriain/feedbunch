require 'feedzirra'
require 'rest_client'

##
# This class can fetch feeds and parse them. It also takes care of caching, sending HTTP headers
# that indicate the server to send only new entries.

class FeedClient

  ##
  # Fetch a feed, parse it and save the entries in the database. This is a class method.
  #
  # The method tries to use the last received etag with the if-none-match header to indicate the server to send only new
  # entries.
  #
  # If no etag was received last time the feed was fetched, it tries to use the last received last-modified header with the
  # if-modified-since request header to indicate the server to send only new entries.
  #
  # If the last time the feed was fetched no etag and no last-modified headers were in the response, this method fetches
  # the full feed without sending caching headers.

  def self.fetch(feed_id)
    feed = Feed.find feed_id

    # Calculate HTTP headers to be used for fetching
    headers = fetch_headers feed

    # GET the feed
    feed_response = RestClient.get feed.fetch_url, headers

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
      save_entries feed, feed_parsed.entries

      feed.save

    else
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
    end

    return true
  rescue RestClient::NotModified => e
    Rails.logger.info "Feed #{feed.fetch_url} returned 304 - not modified"
    return true
  end

  private

  ##
  # Save feed entries in the database. This is a class method.
  # For each entry, if an entry with the same guid already exists in the database, update it with
  # the values passed as argument to this method. Otherwise save it as a new entry in the database.
  #
  # The argument passed are:
  # - the feed to which the entries belong (an instance of the Feed model)
  # - an Enumerable with the feed entries to save.

  def self.save_entries(feed, entries)
    entries.each do |f|
      # If entry is already in the database, update it
      if Entry.exists? guid: f.entry_id
        e = Entry.where(guid: f.entry_id).first
        Rails.logger.info "Updating already saved entry for feed #{feed.fetch_url} - title: #{f.title} - guid: #{f.entry_id}"
        # Otherwise, save a new entry in the DB
      else
        e = Entry.new
        Rails.logger.info "Saving in the database new entry for feed #{feed.fetch_url} - title: #{f.title} - guid: #{f.entry_id}"
      end

      e.title = f.title
      e.url = f.url
      e.author = f.author
      e.content = f.content
      e.summary = f.summary
      e.published = f.published
      e.guid = f.entry_id
      feed.entries << e
      e.save
    end
  end

  ##
  # Return the HTTP headers to be used for fetching a feed, in order to cache content as much as possible.
  # This is a class method.
  #
  # It receives as an argument the feed that is going to be fetched
  #
  # The method tries to use the last received etag with the if-none-match header to indicate the server to send only new
  # entries.
  #
  # If no etag was received last time the feed was fetched, it tries to use the last received last-modified header with the
  # if-modified-since request header to indicate the server to send only new entries.
  #
  # If the last time the feed was fetched no etag and no last-modified headers were in the response, this method fetches
  # the full feed without sending caching headers.

  def self.fetch_headers(feed)
    headers = {}
    # Prefer to use etag for cache control
    if feed.etag.present?
      Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with etag: #{feed.etag}"
      headers = {if_none_match: feed.etag}
      # If etag is not saved, try to use last-modified for cache control
    elsif feed.last_modified.present?
      Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with last-modified: #{feed.last_modified}"
      headers = {if_modified_since: feed.last_modified}
    else
      Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with no cache control headers"
    end

    return headers
  end
end