require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

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

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Use Rack::Deflater middleware to compress server responses when the client supports it.
    config.middleware.use Rack::Deflater

    # Rails generators generate FactoryGirl factories instead of fixtures
    config.generators do |g|
      g.fixture_replacement :factory_girl
    end

    # Whitelist of accepted tags and attributes when sanitizing entries, folder titles etc.
    # This list is a more restrictive version of:
    # https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/whitelist.rb
    config.action_view.sanitized_allowed_attributes = %w[alt border cite colspan color coords datetime
      dir headers href hreflang ismap label lang loop loopcount loopend loopstart media poster preload
      rel rev rowspan scope shape span src start summary target title usemap]
    config.action_view.sanitized_allowed_tags = %w[a abbr acronym address area
      article aside audio b bdi bdo big blockquote br canvas
      caption center cite code col colgroup dd del
      dfn div dl dt em figcaption figure footer
      h1 h2 h3 h4 h5 h6 header hr i img ins kbd
      li map mark nav ol p
      pre q s samp section small span strike strong sub
      sup table tbody td tfoot th thead time tr tt u ul var
      video]

    # Most devise views use the devise layout except "edit_registration", which uses its own layout
    config.to_prepare do
      Devise::RegistrationsController.layout proc{|controller| user_signed_in? ? 'user_profile' : 'devise'}
    end

    # Append the lib directory to the autoload path while in development
    config.autoload_paths += %W(#{config.root}/lib)

    # Use dynamic error pages
    config.exceptions_app = self.routes

    # Maximum and minimum interval between updates for each feed, regardless of how often new entries appear.
    config.max_update_interval = 6.hours
    config.min_update_interval = 15.minutes

    # If a feed fails to update for longer than this time, autodiscovery will be attempted on its webpage (in case
    # the url works but the fetch_url has been changed)
    config.autodiscovery_after = 1.day

    # If a feed fails to update for longer than this time, it is marked as permanently unavailable (no more
    # updates will be attempted)
    config.unavailable_after = 1.month

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

    # Daily invitations limit for each user
    config.daily_invitations_limit = 50

    # Interval after which an unaccepted invitation will be discarded
    config.discard_unaccepted_invitations_after = 1.month

    # Interval after which an unconfirmed signup will be discarded
    config.discard_unconfirmed_signups_after = 1.month
    # Intervals to send reminders to unconfirmed users
    config.first_confirmation_reminder_after = 1.day
    config.second_confirmation_reminder_after = 1.week
  end
end
