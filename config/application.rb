require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
# require "action_view/railtie"  # Comment this out for pure API
require "action_cable/engine"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module AgriculturalLogistics
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true

    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.generators.system_tests = nil
  end
end