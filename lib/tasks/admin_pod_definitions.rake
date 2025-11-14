# lib/tasks/admin_pod_definitions.rake
namespace :admin do
  namespace :pod_definitions do
    desc "Validate pod definitions YAML"
    task validate: :environment do
      begin
        Admin::PodSchemas.validate!
        puts "Pod definitions validation: OK"
      rescue => e
        warn "Validation failed: #{e.class}: #{e.message}"
        exit 1
      end
    end

    desc "Reload pod definitions (development convenience)"
    task reload: :environment do
      Admin::PodSchemas.reload!
      puts "Pod definitions reloaded"
      begin
        Admin::PodSchemas.validate!
        puts "Validation after reload: OK"
      rescue => e
        warn "Validation failed after reload: #{e.class}: #{e.message}"
        exit 1
      end
    end
  end
end
