source 'https://rubygems.org'

ruby '2.2.3'

gem 'rails', '~> 4.2.0'

# Sanitizer to replace poorly maintained new rails sanitizer
gem 'sanitize'

gem 'responders'
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'

gem 'jquery-rails'

# Integrate bower (frontend package manager) with rails
gem 'bower-rails', '~> 0.10.0'

# Ruby profiling
gem 'ruby-prof'

# Serve the app with Puma
gem 'puma'

# Use Redis for Rails caching
gem 'redis-rails'

# To more easily serve static pages
gem 'high_voltage'

# User authentication
gem 'devise'

# App is invitation-only while in beta stage!
gem 'devise_invitable'

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

# HTTP client-side caching
gem 'rest-client-components'
gem 'rack-cache', git: 'https://github.com/amatriain/rack-cache.git', branch: 'unparseable_expires'

# URI implementation with better support for RFC 3986, RFC 3987, and RFC 6570 (level 4)
gem 'addressable'

# To parse html
gem 'nokogiri'

# Background jobs
gem 'sidekiq', '>= 3.2.5'
gem 'sidetiq'
gem 'sidekiq-superworker'

# Sinatra required for the Sidekiq web ui
gem 'sinatra', '>= 1.3.0', :require => nil

# Web GUI for Redis instances
gem 'redmon', require: false

# Authorization management
gem 'cancancan'

# Manage zip files
gem 'rubyzip'

# Use the Accept-language HTTP header for i18n
gem 'http_accept_language'

# Administration interface
gem 'activeadmin', git: 'https://github.com/activeadmin/activeadmin.git'

# Insight into PostgreSQL database
gem 'pghero'

group :development do
  # Automate deployments
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false

  # App preloader to speed up tests, new in Rails 4.1.0
  gem 'spring'

  # Irb-like console in error pages, new in Rails 4.2
  gem 'web-console', '~> 2.0'
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

  # Testing framework
  gem 'rspec-rails'

  # Factories instead of DB fixtures during testing
  gem 'factory_girl_rails'
end

group :test do
  # Testing
  gem 'rspec'

  # Retry failed tests
  gem 'rspec-retry'

  # Code coverage
  gem 'coveralls', require: false

  # To simulate a user's browser during acceptance testing
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'show_me_the_cookies'

  # To be able to open the browser during debugging of acceptance tests
  gem 'launchy'

  # To empty the database between acceptance tests
  gem 'database_cleaner'
end

group :staging, :production do
  # PostgreSQL database for staging and production
  gem 'pg'

  # Access Amazon AWS services
  gem 'aws-sdk-rails'

  # Analytics
  gem 'newrelic_rpm'
end
