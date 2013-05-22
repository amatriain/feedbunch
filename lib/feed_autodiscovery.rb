##
# Class to performs feed autodiscovery on an HTML document.

class FeedAutodiscovery
  ##
  # Try to perform feed autodiscovery on an HTTP response, with the assumption that it's an HTML document.
  #
  # If successful, save the new feed in the database and return it. At this point:
  # - there are no entries in the database for the feed.
  # - the feed fetch_url and title fields both have the same value, the URL retrieved from the HTML.
  # - the feed has no url.
  #
  # It's the responsability of the calling function to fetch the feed afterwards, to populate entries, title, URL etc.
  #
  # Receives as arguments the feed object to be associated with the discovered feed, and the response with the HTML document.
  #
  # Any errors raised are bubbled to be handled higher up the call chain. In particular, if the response on which
  # autodiscovery is being performed is not an HTML document, an error will be raised.
  #
  # Returns the updated feed object if autodiscovery is successful, or nil if the HTML didn't have a feed associated.

  def self.perform_feed_autodiscovery(feed, feed_response)
    Rails.logger.info "Could not parse feed from url #{feed.fetch_url}. Trying to perform feed autodiscovery"
    doc = Nokogiri::HTML feed_response

    # In this order, give preference to Atom, then to RSS, then to generic "feed" links
    xpath_atom = '//head//link[@rel="alternate"][@type="application/atom+xml"]'
    xpath_rss = '//head//link[@rel="alternate"][@type="application/rss+xml"]'
    xpath_feed = '//head//link[@rel="feed"]'
    feed_link = doc.at_xpath(xpath_atom + '|' + xpath_rss + '|' + xpath_feed)

    feed_href = feed_link.try(:attr, 'href').try(:to_s)
    if feed_href.present?
      # If the href is a path without fqdn, i.e. "/feeds.php", prepend it with the scheme and fqdn of the webpage
      uri = URI feed_href
      if uri.host.blank?
        uri_webpage = URI feed.fetch_url
        uri.scheme = uri_webpage.scheme
        uri.host = uri_webpage.host
        Rails.logger.info "Retrieved feed path #{feed_href}, converted to full URL #{uri.to_s}"
        feed_href = uri.to_s
      end

      Rails.logger.info "Autodiscovered feed with url #{feed_href}. Updating feed in the database."
      feed.fetch_url = feed_href
      feed.save!
      return feed
    else
      Rails.logger.warn "Feed autodiscovery failed for #{feed.fetch_url}"
      return nil
    end
  end
end