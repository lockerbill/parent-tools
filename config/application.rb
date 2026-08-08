require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Homedojo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # The whole household lives in one timezone. Override with TZ in the container.
    config.time_zone = ENV.fetch("TZ", "UTC")
    config.active_record.default_timezone = :utc

    # Home-lab installs are usually reached over http on the LAN, so the app must
    # not force TLS unless the operator opts in (see config/environments/production.rb).
    config.action_view.field_error_proc = ->(html_tag, _instance) { html_tag }

    # Keep generated files lean.
    config.generators do |g|
      g.test_framework :test_unit, fixture: true
      g.helper false
      g.javascript_engine false
    end
  end
end
