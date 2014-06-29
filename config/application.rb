require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

##
# Main module of the Feedbunch application. Most classes will be namespaced inside
# this module.

module Feedbunch

  ##
  # Main class of the Feedbunch application. Global settings are set here.

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'UTC'

    # Do not raise an error if an unavailable locale is passed (the default :en will be used,
    # see config.i18n.fallbacks below)
    config.i18n.enforce_available_locales = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Fall back to the default locale ("en" if config.i18n.default_locale is not configured)
    # if the locale sent by the user does not exist
    config.i18n.fallbacks = true

    # Use Rack::Deflater middleware to compress server responses when the client supports it.
    config.middleware.use Rack::Deflater

    # Rails generators generate FactoryGirl factories instead of fixtures
    config.generators do |g|
      g.fixture_replacement :factory_girl
    end

    # Add "target" html attribute to the whitelist when using the sanitize helpers.
    # This is necessary because otherwise all "target" attributes are filtered out, which means that the app cannot
    # create links with target="_blank" that open in a new tab.
    # We really want links in feed entries to open in a new tab!
    config.action_view.sanitized_allowed_attributes = %w(target)

    # Most devise views use the devise layout except "edit_registration", which uses its own layout
    config.to_prepare do
      Devise::RegistrationsController.layout proc{|controller| user_signed_in? ? 'user_profile' : 'devise'}
    end

    # Append the lib directory to the autoload path while in development
    config.autoload_paths += %W(#{config.root}/lib)

    # Use dynamic error pages
    config.exceptions_app = self.routes

    # Maximum and minimum interval between updates for each feed, regardless of how often new entries appear.
    config.max_update_interval = 12.hours
    config.min_update_interval = 15.minutes

    # If a feed's update fail for more than this time, the feed is marked as permanently unavailable (no more
    # updates will be attempted)
    config.unavailable_after = 1.week

    # Job state alerts (subscribe_job and refresh_feed_job) when they are older than this
    config.destroy_job_states_after = 24.hours

    # User-agent that feedbunch will use when fetching feeds
    config.user_agent = 'Feedbunch/1.0 (+http://www.feedbunch.com)'

    # Maximum number of entries to keep for each feed.
    config.max_feed_entries = 500

    # List of currently available locales
    I18n.available_locales = [:en, :es]

    # Admin email
    config.admin_email = 'admin@feedbunch.com'

    # Interval after which an unaccepted invitation will be discarded
    config.discard_unaccepted_invitations_after = 1.month
  end
end
