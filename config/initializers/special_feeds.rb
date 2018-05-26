# Load feeds that need special fetching and handling from the YAML config file.
# If the config file changes the server must be restarted to pick up changes.

require 'addressable/uri'

list = YAML.load_file 'config/special_feeds.yml'

# We actually store the host for each URL in the list, which is what we're actually interested in.
# Also for each host we store the actual fetcher and/or handler class, not the string with its name.
# This behavior is fail-fast: if the config file has the name of a class that does not exist, an error will raise
# during app startup.
special_feeds_fetchers = {}
special_feeds_handlers = {}
list.keys.each do |url|
  special_url = URLNormalizer.normalize_feed_url(url).strip.downcase
  special_host = Addressable::URI.parse(special_url).host

  fetcher = list[url]['fetcher']
  if fetcher.present?
    fetcher_class = fetcher.constantize
    special_feeds_fetchers[special_host] = fetcher_class
  end

  handler = list[url]['handler']
  if handler.present?
    handler_class = handler.constantize
    special_feeds_handlers[special_host] = handler_class
  end
end

Rails.application.config.special_feeds_fetchers = special_feeds_fetchers
Rails.application.config.special_feeds_handlers = special_feeds_handlers
