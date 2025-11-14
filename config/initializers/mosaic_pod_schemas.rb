# Load pod schemas at boot and setup dev hot-reload

# Ensure the service is loaded even if app/services is not yet autoloaded
require_dependency Rails.root.join("app", "services", "admin", "pod_schemas").to_s

Admin::PodSchemas.instance

if Rails.env.development?
  pod_paths = [
    Rails.root.join("config", "pod_definitions.yml"),
    Rails.root.join("docs", "pod_definitions.yml")
  ].select { |p| File.exist?(p) }

  reloader = ActiveSupport::FileUpdateChecker.new(pod_paths) do
    Rails.logger.info("[Admin::PodSchemas] Reloading pod definitions after change...")
    Admin::PodSchemas.reload!
    begin
      Admin::PodSchemas.validate!
      Rails.logger.info("[Admin::PodSchemas] Validation OK")
    rescue => e
      Rails.logger.error("[Admin::PodSchemas] Validation error: #{e.message}")
    end
  end

  Rails.application.reloaders << reloader

  ActiveSupport::Reloader.to_prepare do
    reloader.execute_if_updated
  end
end
