##
# Class to calculate what HTTP headers to use when fetching a feed.
#
# The headers returned by this class give the necessary information to the feed server
# to leverage HTTP caching.

class FeedCaching

  ##
  # Return the HTTP headers to be used for fetching a feed, in order to cache content as much as possible.
  #
  # It receives as an argument the feed that is going to be fetched
  #
  # The method tries to use the last received etag with the if-none-match header and the last received
  # last-modified with the if-modified-since header to tell the server to send the feed only if it has new entries.
  #
  # If the last time the feed was fetched no etag and no last-modified headers were in the response, no caching headers
  # are set, which means the full feed will be fetched unconditionally.

  def self.fetch_headers(feed)
    headers = {}

    if feed.etag.present?
      Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with etag: #{feed.etag}"
      headers[:if_none_match] = feed.etag
    end

    if feed.last_modified.present?
      Rails.logger.info "Fetching feed XML from: #{feed.fetch_url} with last-modified: #{feed.last_modified}"
      headers[:if_modified_since] = feed.last_modified
    end

    return headers
  end
end