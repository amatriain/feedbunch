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