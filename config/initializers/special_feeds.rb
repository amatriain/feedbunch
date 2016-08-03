# Load feeds that need special handling from the YAML config file.
# If the config file changes the server must be restarted to pick up changes.

require 'addressable/uri'

list = YAML.load_file 'config/special_feeds.yml'

# We actually store the host for each URL in the list, which is what we're actually interested in.
# Also for each host we store the actual handler class, not the string with its name.
# This behavior is fail-fast: if the config file has the name of a class that does not exist, an error will raise
# during app startup.
special_feeds = {}
list.keys.each do |url|
  special_url = URLNormalizer.normalize_feed_url(url).strip.downcase
  special_host = Addressable::URI.parse(special_url).host
  handler = list[url].constantize

  special_feeds[special_host] = handler
end

Rails.application.config.special_feeds = special_feeds
