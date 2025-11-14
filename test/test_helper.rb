ENV["RAILS_ENV"] ||= "test"
# Minimal ENV to satisfy strict Settings fetches during test boot
ENV["BUNNY_ACCESS_KEY"] ||= "test"
ENV["BUNNY_API_KEY"] ||= "test"
ENV["BUNNY_STORAGE_ZONE"] ||= "test"
ENV["BUNNY_REGION"] ||= "test"
ENV["BUNNY_CDN_ENDPOINT"] ||= "https://cdn.example.com"

require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end
