source "https://rubygems.org"

ruby "3.4.7"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# === REDIS STACK (Rails 8 Compatible) ===
# Redis client for Rails caching and Action Cable
gem "redis", "~> 5.0"
gem "action-cable-redis-backport", "~> 1"
gem "redis-session-store", "~> 0.11.5"

# Background job processing with Sidekiq (Rails 8 compatible)
gem "sidekiq", "~> 8.0"

# Redis connection pool for better performance
gem "connection_pool", "~> 2.5"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# === MOSAIC CMS GEMS ===
# Authentication
gem "devise"

# Authorization
gem "pundit"

# Image processing for ActiveStorage variants and thumbnails (using VIPS)
gem "image_processing", "~> 1.2"

# Rich text editor
gem "tinymce-rails"

# SVG handling and optimization
gem "inline_svg", "~> 1.9"
gem "svg_optimizer", "~> 0.3"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "annotate"

  # Autoload dotenv in Rails.
  gem "dotenv-rails", "~> 3.1", ">= 3.1.8"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

# Hierarchical structures for pages and page_pods
gem "ancestry", "~> 4.3"

gem "friendly_id", "~> 5.5"

gem "acts_as_list"

# settings.yml
gem "config"

# bunny CDN
gem "active_storage_bunny"

# audit logs
gem "paper_trail"
