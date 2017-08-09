source 'https://rubygems.org'

ruby '2.4.1'

gem 'rails', '~> 5.1.3'

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
gem 'rest-client-components', git: 'https://github.com/amatriain/rest-client-components.git', branch: 'rest-client-2-compatibility'
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
gem 'redmon'
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

group :development do
  # Automate deployments
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false

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

  # Testing framework
  gem 'rspec-rails'

  # Factories instead of DB fixtures during testing
  gem 'factory_girl_rails'
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
