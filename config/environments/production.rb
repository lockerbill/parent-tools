require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files (child avatars) on the local file system under storage/.
  config.active_storage.service = :local

  # HOME LAB DEFAULTS -------------------------------------------------------
  # Most installs are reached over plain http on the LAN or over Tailscale, where
  # forcing TLS just breaks the app. Set FORCE_SSL=1 once you are behind a
  # TLS-terminating reverse proxy (Traefik, Caddy, Nginx Proxy Manager).
  config.assume_ssl = ENV["FORCE_SSL"].present?
  config.force_ssl  = ENV["FORCE_SSL"].present?
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Rails 8 blocks unknown Host headers. Home labs use names like homedojo.lan or
  # a Tailscale MagicDNS name, so allow them through APP_HOSTS (comma separated).
  if ENV["APP_HOSTS"].present?
    config.hosts += ENV["APP_HOSTS"].split(",").map(&:strip).reject(&:blank?)
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  else
    # No allow-list configured: accept any host (typical LAN-only install).
    config.hosts.clear
  end
  # -------------------------------------------------------------------------

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Database-backed cache and queue: no Redis, no extra containers.
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Email is optional. Without SMTP_ADDRESS the app simply never sends mail, which
  # keeps the default install free of any external dependency.
  config.action_mailer.perform_deliveries = ENV["SMTP_ADDRESS"].present?
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost:3000"),
    protocol: ENV["FORCE_SSL"].present? ? "https" : "http"
  }

  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"],
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      domain: ENV["SMTP_DOMAIN"].presence,
      user_name: ENV["SMTP_USER_NAME"].presence,
      password: ENV["SMTP_PASSWORD"].presence,
      authentication: ENV["SMTP_AUTHENTICATION"].presence&.to_sym,
      enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true"
    }.compact
  end

  # Enable locale fallbacks for I18n.
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]
end
