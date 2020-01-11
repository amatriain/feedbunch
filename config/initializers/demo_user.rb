# frozen_string_literal: true

# Configuration for the demo user. It is reset every hour by the ResetDemoUserWorker sidekiq worker.

# If this config is not set to true, the demo user will be disabled. In fact each run of ResetDemoUserWorker will
# delete it if it exists.
# If this config is not set to true the rest of options in this file will be ignored.
Feedbunch::Application.config.demo_enabled = true

# Demo user authentication
Feedbunch::Application.config.demo_email = 'demo@feedbunch.com'
Feedbunch::Application.config.demo_password = 'feedbunch-demo'

# Demo user config
Feedbunch::Application.config.demo_name = 'demo user'
Feedbunch::Application.config.demo_quick_reading = false
Feedbunch::Application.config.demo_open_all_entries = false

# Demo user folders and subscribed feeds.
# The config is a hash in which:
# - each key is the name of a folder
# - each value is an array containing the fetch_urls of the feeds in the folder
# As a special case, a key can be Folder::NO_FOLDER. In this case the value is an array
# containing the fetch_urls of the subscribed feeds which aren't in a folder.
no_folder_feeds = %w(http://opensource.googleblog.com/
                      http://clarkesworldmagazine.com/feed/)
comic_feeds = %w(http://xkcd.com/atom.xml
                  http://pbfcomics.com/feed/feed.xml
                  http://feeds.penny-arcade.com/pa-mainsite/)
webdev_feeds = %w(https://blog.angular.io/
                  http://blog.getbootstrap.com/
                  http://weblog.rubyonrails.org/)
Feedbunch::Application.config.demo_subscriptions = {'none' => no_folder_feeds,
                                                    'comics' => comic_feeds,
                                                    'web development' => webdev_feeds}
