# frozen_string_literal: true

require 'url_normalizer'

# Load blacklisted hosts from the YAML config file.
# If the config file changes the server must be restarted to pick up changes.

require 'addressable/uri'

list = YAML.load_file 'config/url_blacklist.yml'

# We actually store the host for each URL in the blacklist, which is what we're actually interested in
blacklist = []
list['aede_urls'].each do |url|
  blacklisted_url = UrlNormalizer.normalize_feed_url(url).downcase
  blacklisted_host = Addressable::URI.parse(blacklisted_url).host
  blacklist << blacklisted_host
end

Rails.application.config.hosts_blacklist = blacklist
