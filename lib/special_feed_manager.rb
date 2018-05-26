require 'url_normalizer'

##
# Class to handle feeds that need special handling.
# The handling for each particular special feed is delegated to a specific class that implements the particular handling.

class SpecialFeedManager
  # Constants for the diferent types of classes needed for special feeds
  FETCHER = :fetcher
  HANDLER = :handler

  ##
  # Check configuration to see if the entry belongs to a feed that needs special handling. In this case,
  # return the handler class; this class implements the handle_entry method, that may change the entry or even prevent
  # it from being saved.
  #
  # If the entry does not belong to a feed that needs special handling, returns nil.
  # If the feed associated with the entry is not present, returns nil.
  #
  # Receives as argument the entry to check.

  def self.get_special_handler(entry)
    if entry.feed.present?
      handler = class_for_feed entry.feed, HANDLER
      if handler.present?
        return handler
      end
    end

    return nil
  end

  ##
  # Check configuration to see if the feed needs special fetching. In this case, return the fetcher class; this class
  # implements the fetch_feed method, that does whatever is necessary to fetch the feed and returns the response.
  #
  # If the feed does not need special handling, returns nil.
  #
  # Receives as argument the feed to check.

  def self.get_special_fetcher(feed)
    fetcher = class_for_feed feed, FETCHER
    if fetcher.present?
      return fetcher
    end

    return nil
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Check if the passed feed is one of the special feeds from the special_feeds.yml config file.
  # In this case, return either the special fetcher class or the special handler class for this URL depending
  # on the second argument.
  #
  # Returns nil if the passed url's host does not match a special feed from the configuration.
  #
  # Receives as argument:
  # - feed to check against the list
  # - type of the special class to be retrieved, either HANDLER or FETCHER

  def self.class_for_feed(feed, type)
    special_class = class_for_url feed.url, type

    if special_class.present?
      # feed.url matches a special feed, no need to look at feed.fetch_url as well
      Rails.logger.info "Feed #{feed.id} - #{feed.title} with url #{feed.url} is a feed with special #{type} class #{special_class}"
    else
      special_class = class_for_url feed.fetch_url, type
      if special_class.present?
        # feed.fetch_url matches a special feed
        Rails.logger.info "Feed #{feed.id} - #{feed.title} with fetch_url #{feed.fetch_url} is a feed with special #{type} class #{special_class}"
      end
    end

    return special_class
  end
  private_class_method :class_for_feed

  ##
  # Check if the host of the passed url matches or is a subdomain of one of the special feeds from the special_feeds.yml
  # config file. In this case, return either the special fetcher class or the special handler class for this URL depending
  # on the second argument.
  #
  # Returns nil if the passed url's host does not match a special feed from the configuration.
  # Returns nil if the passed url is blank or nil.
  # Returns nil if the passed type is not HANDLER or FETCHER.
  #
  # Receives as argument:
  # - url string to check against the list
  # - type of the special class to be retrieved, either HANDLER or FETCHER

  def self.class_for_url(url, type)
    return nil if url.blank?
    return nil if type!=HANDLER && type!=FETCHER

    # Add uri-scheme if missing, convert to downcase and remove extra whitespaces so that it can be parsed
    # to extract the host
    compare_url = URLNormalizer.normalize_feed_url(url).strip.downcase
    compare_host = Addressable::URI.parse(compare_url).host

    if type == FETCHER
      specials_list = Rails.application.config.special_feeds_fetchers
    elsif type == HANDLER
      specials_list = Rails.application.config.special_feeds_handlers
    end
    special_urls = specials_list.keys

    special_class = nil
    special_urls.each do |s|
      # Use regex to see if passed host matches or is subdomain of the blacklisted url's host
      if /\A(.+\.)*#{s}\z/ =~ compare_host
        special_class = specials_list[s]
        Rails.logger.info "URL #{url} matches special host #{s}, special #{type} class #{special_class}"
        break
      end
    end
    return special_class
  end
  private_class_method :class_for_url

end
