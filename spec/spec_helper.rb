require 'coveralls'
Coveralls.wear!('rails')

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# For acceptance testing
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/rspec'
require 'database_cleaner'
require 'nokogiri'

# Factories instead of database fixtures
require 'factory_girl_rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Clean the database between tests with database_cleaner
  config.before(:suite)  {DatabaseCleaner.strategy = :deletion}
  config.before(:each) {DatabaseCleaner.start}
  config.after(:each) {DatabaseCleaner.clean}

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # To test controllers protected by Devise authentication
  config.include Devise::TestHelpers, :type => :controller

  # Use capybara-webkit for javascript-enabled acceptance tests
  Capybara.javascript_driver = :webkit

  # methods stubbed in all specs
  config.before :each do
    # Ensure no HTTP calls are made during testing
    RestClient.stub :get

    # ensure no attempt to connect to Redis is done
    Resque.stub :set_schedule
    Resque.stub :remove_schedule
    Resque.stub :enqueue
    Resque.stub :enqueue_in
  end
end
