# frozen_string_literal: true

require 'url_normalizer'

##
# Class to determine if a feed is in the blacklist or not.

class FeedBlacklister

  ##
  # Check if the passed feed belongs to one of the blacklisted websites from the url_blacklist.yml config file.
  #
  # Receives as argument the feed to check against the blacklist.
  #
  # Returns true if either the url or fetch_url of the feed is a sub-url of a blacklisted URL, false otherwise.

  def self.blacklisted_feed?(feed)
    blacklisted = false

    if !blacklisted_url? feed.url
      if blacklisted_url? feed.fetch_url
        # feed.fetch_url is blacklisted
        Rails.logger.warn "Feed #{feed.id} - #{feed.title} with fetch_url #{feed.fetch_url} is blacklisted"
        blacklisted = true
      end
    else
      # feed.url is blacklisted, no need to look at feed.fetch_url as well
      Rails.logger.warn "Feed #{feed.id} - #{feed.title} with url #{feed.url} is blacklisted"
      blacklisted = true
    end

    return blacklisted
  end

  ##
  # Check if the passed url's host matches or is a subdomain of one of the blacklisted websites from the url_blacklist.yml
  # config file.
  #
  # Receives as argument the url string to check against the blacklist.
  #
  # Returns true if the url host is blacklisted or a subdomain of a blacklisted host, false otherwise.
  #
  # If the passed string is blank or nil, returns false.

  def self.blacklisted_url?(url)
    return false if url.blank?

    # Add uri-scheme if missing, convert to downcase and remove extra whitespaces so that it can be parsed
    # to extract the host
    compare_url = URLNormalizer.normalize_feed_url(url).strip.downcase
    compare_host = Addressable::URI.parse(compare_url).host

    blacklist = Rails.application.config.hosts_blacklist
    blacklisted = false
    blacklist.each do |b|
      # Use regex to see if passed host matches or is subdomain of the blacklisted url's host
      if /\A(.+\.)*#{b}\z/ =~ compare_host
        Rails.logger.warn "URL #{url} matches blacklisted host #{b}"
        blacklisted = true
        break
      end
    end
    return blacklisted
  end
end
