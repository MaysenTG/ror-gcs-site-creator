source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.3"

gem "rails", "~> 8.1.0"

# Keep Sprockets (Rails 8 defaults to Propshaft for new apps)
gem "sprockets-rails"

gem "pg"
gem "sqlite3", ">= 2.1"
gem "puma"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Redis for Sidekiq + Rails.cache in production
gem "redis"

gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "bootsnap", require: false

gem "devise"
gem "aws-sdk-s3"
gem "httparty"
gem "pagy"
gem "stripe"
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails"
  gem "rspec-rails"
end

group :development do
  gem "web-console"
end
