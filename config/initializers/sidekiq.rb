Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }

  # Queue configuration for Sidekiq 8
  config.queues = %w[critical default low]

  # Or with weights (process critical 3x more than default, default 2x more than low)
  # config.queues = %w[critical critical critical default default low]
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
end

# Job defaults (Sidekiq 8 syntax)
Sidekiq.default_job_options = {
  retry: 3,
  backtrace: true
}

# Optional: Error handling
Sidekiq.configure_server do |config|
  config.error_handlers << proc do |exception, context|
    Rails.logger.error "Sidekiq job failed: #{exception.message}"
    Rails.logger.error "Context: #{context}"
  end
end

# Optional: Lifecycle hooks
Sidekiq.configure_server do |config|
  config.on(:startup) do
    Rails.logger.info "Sidekiq server started"
  end

  config.on(:shutdown) do
    Rails.logger.info "Sidekiq server stopping"
  end
end