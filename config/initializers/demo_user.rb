# frozen_string_literal: true

# Configuration for the demo user. If enabled, it is reset every hour by the ResetDemoUserWorker sidekiq worker.

# The DEMO_USER_ENABLED environment variable can be used to enable or disable the demo user (enabled by default).
# If set to "true" or the env variable is unset, the demo user is enabled. If set to "false" the demo user is disabled.
# If the demo user is disabled the rest of options in this file will be ignored.
demo_enabled_str = ENV.fetch("DEMO_USER_ENABLED") { "true" }
demo_enabled_str = demo_enabled_str.downcase.strip
demo_enabled = ActiveRecord::Type::Boolean.new.cast demo_enabled_str
Feedbunch::Application.config.demo_enabled = demo_enabled

if demo_enabled
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
end
