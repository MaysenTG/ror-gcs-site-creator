require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Fly.io and similar hosts serve static assets from the app process.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || ENV["FLY_APP_NAME"].present?

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  config.action_cable.allowed_request_origins = [
    ENV["APP_ORIGIN"].presence,
    "https://#{ENV['APP_HOST']}".presence,
    "https://static-site-creator.fly.dev",
    /https:\/\/.*\.maysengreenwood\.com/,
    /https:\/\/.*\.fly\.dev/
  ].compact

  # Fly terminates TLS; tell Rails the original request was HTTPS.
  config.assume_ssl = ENV["RAILS_ASSUME_SSL"].present? || ENV["FLY_APP_NAME"].present?

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV["RAILS_FORCE_SSL"].present? || ENV["FLY_APP_NAME"].present?

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Redis cache only if REDIS_URL is set (optional free Upstash). Otherwise memory.
  if ENV["REDIS_URL"].present?
    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], namespace: "static_site_creator", expires_in: 1.hour }
  else
    config.cache_store = :memory_store, { size: 64.megabytes }
  end

  # Default async = no Sidekiq/Redis machine. Set ACTIVE_JOB_ADAPTER=sidekiq only if Redis exists.
  config.active_job.queue_adapter = ENV.fetch("ACTIVE_JOB_ADAPTER", "async").to_sym

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  
  # Multi-tenant custom domains arrive with arbitrary Host headers (via nginx).
  config.hosts.clear
  config.hosts << "maysengreenwood.com"
  config.hosts << /.*\.maysengreenwood\.com/
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
  config.hosts << /.*\.fly\.dev/
  # Allow any host for published custom domains / proxy lookup.
  config.host_authorization = { exclude: ->(req) { req.path.start_with?("/admin/proxy/site/lookup") || req.path == "/up" } }
  # Customer sites may hit the app directly with their own Host.
  config.hosts << /.*/
end
