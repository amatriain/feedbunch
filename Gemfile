source 'https://rubygems.org'

ruby '2.7.0'

#gem 'rails', '~> 5.2.0'
gem 'rails', '6.0.0'

# Avoid updating to sprockets 4 for now
# It completely breaks the asset pipeline in this project
gem 'sprockets', '~> 3.7.2'

# Sanitizer to replace poorly maintained new rails sanitizer
gem 'sanitize'
gem 'loofah'

gem 'responders'
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'

gem 'jquery-rails'

# Integrate bower (frontend package manager) with rails
gem 'bower-rails', '~> 0.11.0'

# Ruby profiling
gem 'ruby-prof'

# Serve the app with Puma
gem 'puma'

# To more easily serve static pages
gem 'high_voltage'

# User authentication
gem 'devise'

# Form generator compatible with Bootstrap
gem 'simple_form'

# Data pagination
gem 'kaminari'

# RSS/Atom parser
gem 'feedjira'
# SAX parser
gem 'sax-machine'
gem 'ox'

# HTTP client
gem 'rest-client'

# headless browser, to fetch some websites behing cloudflare DDOS protection
gem 'selenium-webdriver'

# HTTP client-side caching
gem 'rest-client-components'
gem 'rack-cache'

# URI implementation with better support for RFC 3986, RFC 3987, and RFC 6570 (level 4)
gem 'addressable'

# To parse html
gem 'nokogiri'

# Background jobs
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'sidekiq-superworker'

# Web GUI for Redis instances
gem 'redmon', git: 'https://github.com/amatriain/redmon.git', branch: 'fix-redis-connect'
# Authorization management

gem 'cancancan'

# Manage zip files
gem 'rubyzip'

# Use the Accept-language HTTP header for i18n
gem 'http_accept_language'

# Administration interface
gem 'activeadmin'
gem 'inherited_resources'

# Insight into PostgreSQL database
gem 'pghero'

# Faster startup
gem 'bootsnap', require: false

group :development do
  # Automate deployments
  gem 'capistrano', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rbenv', require: false

  # App preloader to speed up tests, new in Rails 4.1.0
  gem 'spring'

  # Irb-like console in error pages, new in Rails 4.2
  gem 'web-console'
end

group :test, :development do
  # Documentation generator
  gem 'yard'

  # Sqlite database for testing and development
  gem 'sqlite3'

  # Static code vulnerability scanner
  gem 'brakeman', require: false

  # Check the bundle for exploits
  gem 'bundler-audit'

  # Check for N+1 queries (which should not exist)
  gem 'bullet'

  # Testing framework
  gem 'rspec-rails'

  # Factories instead of DB fixtures during testing
  gem 'factory_bot_rails'
end

group :test do
  # Testing
  gem 'rspec'
  # "assigns" method for controller tests has been moved to a different gem in rails 5
  gem 'rails-controller-testing', require: false

  # Retry failed tests
  gem 'rspec-retry'

  # Code coverage
  gem 'coveralls', require: false

  # To simulate a user's browser during acceptance testing
  gem 'capybara'

  # To be able to open the browser during debugging of acceptance tests
  gem 'launchy'

  # To empty the database between acceptance tests
  gem 'database_cleaner'
end

group :staging, :production do
  # PostgreSQL database for staging and production
  gem 'pg'

  # Access Amazon S3 file services
  gem 'aws-sdk-s3'

  # Analytics
  gem 'newrelic_rpm'
end
