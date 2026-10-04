ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# This app is developed with RVM Ruby 3.2.3. System /usr/bin/ruby is also "3.2.3"
# but a different build — native gems won't load across the two.
unless RbConfig.ruby.to_s.include?("/.rvm/rubies/ruby-3.2.3/")
  warn <<~MSG
    Wrong Ruby: #{RbConfig.ruby}
    Run:  rvm use 3.2.3
    Then: bin/bundle install && bin/rails s
    (Do not use /usr/bin/bundle — it installs into system gem paths.)
  MSG
end

require "bundler/setup" # Set up gems listed in the Gemfile.

begin
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
rescue LoadError
  # Native bootsnap/msgpack extensions can fail after Ruby upgrades; app still boots.
end
