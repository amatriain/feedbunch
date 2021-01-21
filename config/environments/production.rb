require 's3_client'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # The FORCE_SECURE environment variable can be used to enable or disable this behavior (enabled by default)
  force_secure_str = ENV.fetch("FORCE_SECURE") { "true" }
  force_secure_str = force_secure_str.downcase.strip
  force_secure = ActiveRecord::Type::Boolean.new.cast force_secure_str
  config.force_ssl = force_secure
  if !force_secure
    config.ssl_options = { redirect: false, secure_cookies: false, hsts: false }
  end

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "feedbunch_production"

  # Use Redis as cache backend.
  config.cache_store = :redis_cache_store, {url: Rails.application.secrets.redis_cache, compress: true}

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  # Email configuration
  config.action_mailer.delivery_method = :smtp
  
  # EMAIL_LINKS_URL environment variable controls the base url for links in emails sent by the app.
  # It uses the value "https://www.feedbunch.com" by default, but should be set to a different value
  # if the app is running in a different host.
  email_links_url = ENV.fetch("EMAIL_LINKS_URL") {"https://www.feedbunch.com"}
  email_uri = URI email_links_url
  email_link_scheme = URI.scheme
  email_link_host = URI.host
  config.action_mailer.default_url_options = { :host => email_link_scheme, protocol: email_link_host }

  config.action_mailer.smtp_settings = {
      address: Rails.application.secrets.smtp_address,
      port: Rails.application.secrets.smtp_port,
      user_name: Rails.application.secrets.smtp_user_name,
      password: Rails.application.secrets.smtp_password,
      authentication: Rails.application.secrets.smtp_authentication.to_sym,
      enable_starttls_auto: true
  }

  # UPLOADS_LOCATION enviroment variable controls the location for file uploads and downloads. 
  # The options here are "s3" (the default), which stores files in the cloud (AWS S3) 
  # and "local", which stores files locally in an uploads folder.
  uploads_location = ENV.fetch("UPLOADS_LOCATION") { "s3" }
  uploads_location = uploads_location.downcase.strip

  case uploads_location
  when "s3"
    Feedbunch::Application.config.uploads_manager = S3Client
  when "local"
    Feedbunch::Application.config.uploads_manager = FileClient
  else
    # if an unrecognized value is passed in UPLOADS_LOCATION, use AWS S3 by default
    Feedbunch::Application.config.uploads_manager = S3Client
  end

  # Use sidekiq as backend for ActiveJob jobs
  config.active_job.queue_adapter = :sidekiq

  # Log level can be controlled with the FEEDBUNCH_LOG_LEVEL env variable.
  # It is "warn" by default. Set it to "debug" to see everything in the log.
  log_level_str = ENV.fetch("FEEDBUNCH_LOG_LEVEL") { "warn" }
  log_level_str = log_level_str.downcase.strip
  log_level = log_level_str.to_sym
  config.log_level = log_level
end
