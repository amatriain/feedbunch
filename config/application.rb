# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

##
# Main module of the Feedbunch application. Most classes will be namespaced inside
# this module.

module Feedbunch

  ##
  # Main class of the Feedbunch application. Global settings are set here.

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Append the lib directory to the autoload path while in development
    config.autoload_paths += %W(#{config.root}/lib)
  end
end
