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

    feed_href = feed_link&.attr('href')&.to_s
    if feed_href.present?
      # If the href is a path without fqdn, i.e. "/feeds.php", prepend it with the scheme and fqdn of the webpage
      feed_href = relative_to_absolute_url feed_href, feed

      # If the href is a relative protocol URL, i.e. "//website.com/feeds.php", prepend it with the scheme of the webpage
      feed_href = relative_to_absolute_protocol feed_href, feed

      # Check if the autodiscovered feed is already in the database
      existing_feed = Feed.url_variants_feed feed_href
      if existing_feed.present? && existing_feed == feed
        # The discovered URL is the one the passed feed already has. No changes in the db are necessary.
        Rails.logger.info "Autodiscovered feed with URL #{feed_href}. Feed #{feed.id} already has this fetch_url, no changes necessary."
        discovered_feed = feed
      elsif existing_feed.present? && existing_feed != feed
        # There is already a feed in the db with the discovered url. Discard the passed feed and subscribe users to the already existing one.
        Rails.logger.info "Autodiscovered already known feed with url #{feed_href}. Using it and destroying feed with url #{feed.url} passed as argument"
        feed.users.find_each do |user|
          Rails.logger.info "User #{user.id} - #{user.email} is subscribed to feed #{feed.url} to be destroyed, subscribing to existing feed #{existing_feed.id} - #{feed_href} instead"
          user.subscribe existing_feed.fetch_url unless user.feeds.include? existing_feed
        end

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

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Convert if necessary a relative URL to an absolute one, based on the feed webpage hostname.
  # Receives as arguments:
  # - URL to convert to absolute if necessary
  # - feed instance to base the URL, if it's relative
  #
  # Returns the URL converted to absolute, if it was relative, or unchanged if it already was absolute

  def self.relative_to_absolute_url(url, feed)
    normalized_url = url.strip
    normalized_url = Addressable::URI.parse(normalized_url).normalize
    if normalized_url.host.blank?
      # Path must begin with a '/'
      normalized_url.path = "/#{normalized_url.path}" if normalized_url.path[0] != '/'

      url_webpage = Addressable::URI.parse feed.fetch_url
      normalized_url.scheme = url_webpage.scheme
      normalized_url.host = url_webpage.host
      Rails.logger.info "Retrieved relative feed path #{url}, converted to absolute URL #{normalized_url}"
    end
    return normalized_url.to_s
  end
  private_class_method :relative_to_absolute_url

  ##
  # Convert if necessary a relative protocol URL (//web.com/feed)to one with the protocol in the
  # URL (http://web.com/feed).
  # The protocol used is the same as the feed webpage, or http:// by default.
  # Receives as arguments:
  # - URL to convert to absolute protocol if necessary
  # - feed instance with the webpage URL using the protocol that will be used for the returned URL.
  #
  # Returns the URL with absolute protocol, if it was a relative protocol URL, or unchanged if it already
  # had absolute protocol.

  def self.relative_to_absolute_protocol(url, feed)
    normalized_url = Addressable::URI.parse(url).normalize
    if normalized_url.scheme.blank?
      url_webpage = Addressable::URI.parse feed.fetch_url
      normalized_url.scheme = url_webpage.scheme
      Rails.logger.info "Retrieved relative feed path #{url}, converted to absolute URL #{normalized_url}"
    end
    return normalized_url.to_s
  end
  private_class_method :relative_to_absolute_protocol
end