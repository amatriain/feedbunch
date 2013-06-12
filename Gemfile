source 'https://rubygems.org'

ruby '1.9.3'

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

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

# Bootstrap goodness!
gem 'bootstrap-sass', '~> 2.3.2.0'

# Better glyphicons from FontAwesome
gem 'font-awesome-rails'

# Better logging
gem 'log4r'

# Form generator compatible with Bootstrap
gem 'simple_form'

# RSS/Atom parser
gem 'feedzirra', git: 'git://github.com/pauldix/feedzirra.git', tag: 'v0.2.0.rc2'

# HTTP client
gem 'rest-client'

# To parse html
gem 'nokogiri'

# Background jobs
gem 'resque'
gem 'resque-scheduler', :require => 'resque_scheduler'

# Process monitoring
gem 'god'

# Automate deployments
gem 'capistrano', require: false
gem 'rvm-capistrano', require: false

# Enable TLS in God email notifications
gem 'tlsmail', require: false

# Authorization management
gem 'cancan'

# Manage zip files
gem 'rubyzip'

group :test, :development do
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

  # To be able to open the browser during debugging of acceptance tests
  gem 'launchy'

  # To empty the database between acceptance tests
  gem 'database_cleaner', '0.9.1'
end

group :staging, :production do
  # Mysql database for staging and production
  gem 'mysql2'
end
