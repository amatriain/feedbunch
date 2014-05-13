source 'https://rubygems.org'

ruby '2.1.2'

gem 'rails', '~> 4.1.0'

gem 'sass-rails', '~> 4.0.2'
gem 'coffee-rails'
gem 'uglifier'

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

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
gem 'sax-machine'

# HTTP client
gem 'rest-client'

# URI implementation with better support for RFC 3986, RFC 3987, and RFC 6570 (level 4)
gem 'addressable'

# To parse html
gem 'nokogiri'

# Background jobs
gem 'resque'
gem 'resque-scheduler', :require => 'resque_scheduler'

# Process monitoring
gem 'god'

# Authorization management
gem 'cancan'

# Manage zip files
gem 'rubyzip'

# Use the Accept-language HTTP header for i18n
gem 'http_accept_language'

# Administration interface
gem 'activeadmin', github: 'gregbell/active_admin'

group :development do
  # Automate deployments
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false
  # App preloader to speed up tests, new in Rails 4.1.0
  gem 'spring'
end

group :test, :development do
  # Documentation generator
  gem 'yard'

  # Sqlite database for testing and development
  gem 'sqlite3'

  # Static code vulnerability scanner
  gem 'brakeman', require: false

  # Testing framework
  gem 'rspec-rails', '~> 2.0'

  # Factories instead of DB fixtures during testing
  gem 'factory_girl_rails'
end

group :test do
  # Code coverage
  gem 'coveralls', require: false

  # To simulate a user's browser during acceptance testing
  gem 'capybara'
  gem 'capybara-webkit'

  # To be able to open the browser during debugging of acceptance tests
  gem 'launchy'

  # To empty the database between acceptance tests
  gem 'database_cleaner'
end

group :staging, :production do
  # PostgreSQL database for staging and production
  gem 'pg'

  # Access Amazon AWS programattically
  gem 'aws-sdk'
end
