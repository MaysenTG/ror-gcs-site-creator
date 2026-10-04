require "sidekiq-cron"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }

  config.on(:startup) do
    schedule_file = Rails.root.join("config/schedule.yml")
    if schedule_file.exist?
      Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_file) || {})
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
end
