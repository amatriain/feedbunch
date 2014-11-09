Feedbunch::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  #  Eager load code on boot. This eager loads most of Rails and
  # your application in memory. This is necessary so that Sidetiq
  # is aware of all worker classes and can display them in the web UI.
  # See: https://github.com/tobiassvn/sidetiq/wiki/Known-Issues
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # To enable caching in a redis backend during development, comment out the line above this and uncomment the following
  # two lines:
  #config.action_controller.perform_caching = true
  #config.cache_store = :redis_store, Rails.application.secrets.redis_cache, {compress: true}

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Links in emails will point to this host
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Upload files to filesystem
  Feedbunch::Application.config.uploads_manager = FileClient

  # Log level
  config.log_level = :debug
end
