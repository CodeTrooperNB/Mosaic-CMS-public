# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::AdminController
  before_action :authenticate_admin_user!

  def index
    @stats = {
      total_pages: Page.count,
      published_pages: Page.published.count,
      draft_pages: Page.where(published: false).count,
      total_users: AdminUser.count
    }

    # Build recent activity feed from PaperTrail versions (last 100)
    activities = []
    if defined?(PaperTrail::Version)
      begin
        # Take the last 100 versions, newest first, then deduplicate by [item_type, item_id]
        versions = PaperTrail::Version.order(created_at: :desc).limit(100)
        unique_versions = versions.each_with_object({}) do |v, seen|
          key = [v.item_type, v.item_id]
          # keep the first (newest) occurrence only
          seen[key] ||= v
        end.values

        unique_versions.each do |v|
          item_type = v.item_type
          item_id = v.item_id

          # Try to load the actual item for richer metadata; fall back to version data
          item = begin
                   v.reify || (item_type.safe_constantize && item_type.safe_constantize.find_by(id: item_id))
                 rescue StandardError
                   nil
                 end

          title = nil
          description = nil
          icon = nil
          time = v.created_at

          case item_type
          when "Page"
            icon = "pages"
            if item
              title = item.title.presence || "Untitled Page"
              description = (v.event == "create") ? "Page created" : "Page updated"
            else
              # fall back to version object
              title = (v.object_changes && begin
                                             (YAML.load(v.object_changes) rescue {})["title"]&.last
                                           end) || "Page ##{item_id}"
              description = v.event == "create" ? "Page created" : "Page updated"
            end
          when "Pod"
            icon = "pods"
            if item
              title = item.name
              description = (v.event == "create") ? "Pod #{item.pod_type} created" : "Pod #{item.pod_type} updated"
            else
              title = "Pod ##{item_id}"
              description = v.event == "create" ? "Pod created" : "Pod updated"
            end
          when "AdminUser"
            icon = "user"
            if item
              title = item.name
              description = v.event == "create" ? "Admin user joined" : "Admin user updated"
            else
              title = "AdminUser ##{item_id}"
              description = v.event == "create" ? "Admin user joined" : "Admin user updated"
            end
          when "PagePod"
            icon = "page_pod"
            title = if v.event == "create"
                      "#{item.pod.name} was added to #{item.page.title}"
                    elsif v.event == "destroy"
                      "#{item.pod.name} was removed from #{item.page.title}"
                    end
            description = v.event == "create" ? "PagePod created" : "PagePod destroyed"
          end

          activities << {
            title: title || "#{item_type} ##{item_id}",
            description: description || "changed",
            icon: icon,
            time: time
          }
        end
      rescue StandardError
        # If PaperTrail or versions aren't available, keep activities empty
        activities = []
      end
    end

    # Sort combined activities by time and take the latest 10
    @recent_activity = activities.compact.sort_by { |a| a[:time] || Time.at(0) }.reverse.first(10)

    # Current sessions for admin users (last 24 hours by current_sign_in_at)
    @current_sessions = begin
                          AdminUser.where("current_sign_in_at > ?", 24.hours.ago)
                                   .order(current_sign_in_at: :desc)
                                   .limit(20)
                        rescue StandardError
                          []
                        end
  end
end