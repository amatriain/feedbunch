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
    feed_xml = http_client.get feed.fetch_url

    if feed_xml.present?
      # We use the actual Feedzirra::Feed class to parse, never a mock.
      # The motivation behind using a mock for fetching the XML during unit testing is not making HTTP
      # calls during testing, but we can always use the real parser even during testing.
      feed_parsed = Feedzirra::Feed.parse feed_xml

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
        feed.entries << e
      end

    else
      Rails.logger.warn "Could not download feed from URL: #{feed.fetch_url}"
    end

    return true
  end
end