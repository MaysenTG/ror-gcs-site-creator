ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

begin
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
rescue LoadError
  # Native bootsnap/msgpack extensions can fail after Ruby upgrades; app still boots.
end
