# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require 'action_cable/engine'
require "sprockets/railtie" # If you use the asset pipeline
require 'active_job/railtie'
require 'action_mailer/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SupplyIqApi
  class Application < Rails::Application
    config.middleware.use Rack::Attack
    # ###################################################################### #
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # ###################################################################### #

    # ###################################################################### #
    # BASIC CONFIGURATION: Common configuration for Rails itself
    # ###################################################################### #
    # #### #
    # Initialize configuration defaults for originally generated Rails version.
    # #### #
    # Add the custom error handling middleware
    config.load_defaults 7.0

    # config.mongoid.logger = Logger.new($stdout, :warn)
    config.mongoid.preload_models = false
    config.mongoid.logger.level = Logger::INFO
    # #### #
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    # #### #
    config.api_only = true
    config.generators do |g|
      g.orm :null
      g.javascripts false
      g.stylesheets false
      g.helper false
      g.channel assets: false
    end

    # #### #
    # Add lib to autoload paths
    # Also add it to eager_load_paths for non-production environments
    # #### #
    config.autoload_paths << "#{Rails.root}/lib/swagger"
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load = false


    # config.active_job.queue_adapter = :delayed
    # config.action_controller.raise_on_open_redirects = false
  end
end
