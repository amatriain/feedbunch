# frozen_string_literal: true

require 'url_normalizer'

# Load blacklisted hosts from the YAML config file.
# If the config file changes the server must be restarted to pick up changes.

require 'addressable/uri'

list = YAML.load_file 'config/host_blacklist.yml'

# Store in the blacklist the host for each line, which is what we're interested in
blacklist = []
if list['hosts'].present?
  list['hosts'].each do |url|
    blacklisted_url = UrlNormalizer.normalize_feed_url(url).downcase
    blacklisted_host = Addressable::URI.parse(blacklisted_url).host
    blacklist << blacklisted_host
  end
end

Rails.application.config.hosts_blacklist = blacklist
