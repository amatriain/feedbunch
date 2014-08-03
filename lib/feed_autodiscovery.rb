##
# Class to performs feed autodiscovery on an HTML document.

class FeedAutodiscovery
  ##
  # Try to perform feed autodiscovery on an HTTP response, with the assumption that it's an HTML document.
  #
  # If successful, save the discovered fetch_url in the database and return the updated feed.
  #
  # This method just updates the fetch_url of the feed with the one autodiscovered from the HTML, it doesn't
  # retrieve entries nor do any other changes. It's the responsability of the invoking code to fetch the feed
  # afterwards, populate entries, title, URL etc.
  #
  # Receives as arguments the feed object to be associated with the discovered fetch_url, and the response object
  # with the HTML document.
  #
  # Any errors raised are bubbled to be handled higher up the call chain. In particular, if the response on which
  # autodiscovery is being performed is not an HTML document, an error will be raised.
  #
  # Returns the updated feed object if autodiscovery is successful, or nil if the HTML didn't have a feed associated.

  def self.discover(feed, feed_response)
    Rails.logger.info "Trying to perform feed autodiscovery on url #{feed.fetch_url}"
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

      # Check if the autodiscovered feed is already in the database
      existing_feed = Feed.url_variants_feed feed_href
      if existing_feed.present? && existing_feed == feed
        # The discovered URL is the one the passed feed already has. No changes in the db are necessary.
        Rails.logger.info "Autodiscovered feed with URL #{feed_href}. Feed #{feed.id} already has this fetch_url, no changes necessary."
        discovered_feed = feed
      elsif existing_feed.present? && existing_feed != feed
        # There is already a feed in the db with the discovered url. Discard the passed feed and return the
        # already existing feed, so that users are subscribed to the already existing feed instead of having
        # a duplicate in the db.
        Rails.logger.info "Autodiscovered already known feed with url #{feed_href}. Using it and destroying feed with url #{feed.url} passed as argument"
        feed.destroy
        discovered_feed = existing_feed
      else
        Rails.logger.info "Autodiscovered new feed with url #{feed_href}. Updating fetch url in the database."
        feed.fetch_url = feed_href
        feed.save!
        discovered_feed = feed
      end

      return discovered_feed
    else
      Rails.logger.warn "Feed autodiscovery failed for #{feed.fetch_url}"
      return nil
    end
  end
end