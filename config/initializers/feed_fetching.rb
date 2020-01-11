# Maximum and minimum interval between updates for each feed, regardless of how often new entries appear.
Rails.application.config.max_update_interval = 6.hours
Rails.application.config.min_update_interval = 15.minutes

# If a feed fails to update for longer than this time, autodiscovery will be attempted on its webpage (in case
# the url works but the fetch_url has been changed)
Rails.application.config.autodiscovery_after = 1.day

# If a feed fails to update for longer than this time, it is marked as permanently unavailable (no more
# updates will be attempted)
Rails.application.config.unavailable_after = 1.month

# User-agent that feedbunch will use when fetching feeds
Rails.application.config.user_agent = 'FeedBunch/1.0 (+http://www.feedbunch.com)'

# Maximum number of entries to keep for each feed.
Rails.application.config.max_feed_entries = 500