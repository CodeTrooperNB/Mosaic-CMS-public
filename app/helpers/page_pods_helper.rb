module PagePodsHelper
  def render_pods(page)
    page_pods = page.page_pods.includes(:pod).visible.ordered_by_position

    page_pods.map do |page_pod|
      render "pods/shared/#{page_pod.pod.pod_type.parameterize.underscore}",
             pod: page_pod.pod,
             data: page_pod.merged_definition,
             last_modified: page_pod.pod.updated_at
    end.join("\n").html_safe
  end
end