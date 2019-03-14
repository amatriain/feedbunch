ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

Gem::Specification.find_by_name('bundler').activate # activate latest bundler version
require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Faster startup
