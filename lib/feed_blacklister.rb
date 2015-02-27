##
# Class to determine if a feed is in the blacklist or not.

class FeedBlacklister

  ##
  # Check if the passed feed belongs to one of the blacklisted websites from the url_blacklist.yml config file.
  #
  # Receives as argument the feed to check against the blacklist.
  #
  # Returns true if either the url or fetch_url of the feed is a sub-url of a blacklisted URL, false otherwise.

  def self.blacklisted?(feed)
    blacklist = Rails.application.config.url_blacklist
    blacklisted = false
    blacklist.each do |u|
      url = u.strip.downcase
      if feed.url.strip.downcase.include?(url) || feed.fetch_url.strip.downcase.include?(url)
        Rails.logger.warn "Feed #{feed.id} - #{feed.title} url:#{feed.url} fetch_url: #{feed.fetch_url} matches blacklisted URL #{url}"
        blacklisted = true
        break
      end
    end
    return blacklisted
  end
end


