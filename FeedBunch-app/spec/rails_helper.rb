# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'rspec/retry'

# For acceptance testing
require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'database_cleaner'
require 'nokogiri'

# Factories instead of database fixtures
require 'factory_bot_rails'

# Use 'assigns' helper method in controller specs
require 'rails-controller-testing'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Clean the database between tests with database_cleaner
  config.before(:suite)  {DatabaseCleaner.strategy = :deletion}
  config.before(:each) {DatabaseCleaner.start}
  config.after(:each) {
    # If database is locked when test is finished (because some database operations are not yet finished),
    # sleep 1 second and try to clean it again. Do it a maximum of 15 times before giving up.
    num_retries = 0
    begin
      DatabaseCleaner.clean
    rescue ActiveRecord::StatementInvalid => e
      num_retries += 1
      if num_retries < 15
        sleep 1
        retry
      else
        raise e
      end
    end
  }

  # Retry failed tests, show retry status in the output
  config.verbose_retry = true
  if Rails.env == 'ci'
    config.default_retry_count = 3
  else
    config.default_retry_count = 1
  end

  # To test controllers protected by Devise authentication
  config.include Devise::Test::ControllerHelpers, type: :controller

  # To test routes protected by Devise authentication
  config.include Warden::Test::Helpers, :type => :request

  # Set driver for acceptance tests
  if ENV['TEST_SUITE'] != 'unit'
    Capybara.register_driver :firefox_headless do |app|
      options = Selenium::WebDriver::Firefox::Options.new
      options.add_argument '--headless'
      options.add_argument '--window-size 1920,1200'
      options.add_argument '--lang en-US,en'
      Capybara::Selenium::Driver.new(app, options: options)
    end
    Capybara.javascript_driver = :firefox_headless
  end

  # Use puma as server for capybara, with logs on to help debugging
  Capybara.server = :puma

  # Make capybara wait for a long time for things to appear in the DOM,
  # in case there's a long-running AJAX call running which changes the DOM after a few seconds
  # (or we're just running in a slow CI environment)
  Capybara.default_max_wait_time = 10

  # Include Warden helpers: login_as, logout...
  # For more about these helpers see Warden wiki: https://github.com/hassox/warden/wiki/Testing
  config.include Warden::Test::Helpers

  # Block external URLs that serve files unnecessary for testing (fonts, twitter API, etc) to speed up tests.
  # This is a whitelist approach: only calls to explicitly allowed hosts or URLs will go through.
=begin
  config.before :each, js: true do
    page.driver.block_unknown_urls
    page.driver.allow_url 'code.jquery.com'
    page.driver.allow_url 'maxcdn.bootstrapcdn.com'
    page.driver.allow_url 'ajax.googleapis.com'
  end
=end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  #config.infer_spec_type_from_file_location!

  # Enable use of 'assigns' helper method in controller tests
  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end
end
