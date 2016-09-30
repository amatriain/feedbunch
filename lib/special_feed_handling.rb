require 'url_normalizer'

##
# Class to handle feeds that need special handling.
# The handling for each particular special feed is delegated to a specific class that implements the particular handling.

class SpecialFeedHandling

  ##
  # Check if the entry belongs to a feed in the configured list of feeds that need special handling. In this case,
  # pass it to the configured handler for this particular feed, that may change the entry or even prevent it from
  # being saved.
  #
  # If the feed associated with the entry is not present, returns nil immediately.
  #
  # Receives as argument the entry to check.

  def self.handle_entry(entry)
    if entry.feed.present?
      handler = handler_for_feed entry.feed
      if handler.present?
        handler.handle_entry entry
      end
    end

    return nil
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Check if the passed feed is one of the special feeds from the special_feeds.yml config file.
  # In this case return the configured handler class for this URL; returns nil otherwise.
  #
  # Receives as argument the feed to check against the list.

  def self.handler_for_feed(feed)
    handler = handler_for_url feed.url

    if handler.present?
      # feed.url matches a special feed, no need to look at feed.fetch_url as well
      Rails.logger.info "Feed #{feed.id} - #{feed.title} with url #{feed.url} is a feed with special handling, handler class #{handler}"
    else
      handler = handler_for_url feed.fetch_url
      if handler.present?
        # feed.fetch_url matches a special feed
        Rails.logger.info "Feed #{feed.id} - #{feed.title} with fetch_url #{feed.fetch_url} is a feed with special handling, handler class #{handler}"
      end
    end

    return handler
  end
  private_class_method :handler_for_feed

  ##
  # Check if the passed url's host matches or is a subdomain of one of the special feeds from the special_feeds.yml
  # config file. In this case, return the configured handler class for this URL; returns nil otherwise
  #
  # Receives as argument the url string to check against the list.
  #
  # If the passed string is blank or nil, returns false.

  def self.handler_for_url(url)
    return nil if url.blank?

    # Add uri-scheme if missing, convert to downcase and remove extra whitespaces so that it can be parsed
    # to extract the host
    compare_url = URLNormalizer.normalize_feed_url(url).strip.downcase
    compare_host = Addressable::URI.parse(compare_url).host

    specials_list = Rails.application.config.special_feeds.keys
    handler = nil
    specials_list.each do |s|
      # Use regex to see if passed host matches or is subdomain of the blacklisted url's host
      if /\A(.+\.)*#{s}\z/ =~ compare_host
        handler = Rails.application.config.special_feeds[s]
        Rails.logger.info "URL #{url} matches special host #{s}, special handler class #{handler}"
        break
      end
    end
    return handler
  end
  private_class_method :handler_for_url

end
