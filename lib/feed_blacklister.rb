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
  # Check if the passed url belongs to one of the blacklisted websites from the url_blacklist.yml config file.
  #
  # Receives as argument the url string to check against the blacklist.
  #
  # Returns true if the url is a sub-url of a blacklisted URL, false otherwise.

  def self.blacklisted_url?(url)
    blacklist = Rails.application.config.url_blacklist
    blacklisted = false
    blacklist.each do |b|
      blacklisted_url = b.strip.downcase
      if url.strip.downcase.include?(blacklisted_url)
        Rails.logger.warn "URL #{url} matches blacklisted URL #{blacklisted_url}"
        blacklisted = true
        break
      end
    end
    return blacklisted
  end
end
