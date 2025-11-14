# app/controllers/admin/page_pods_controller.rb
class Admin::PagePodsController < Admin::AdminController
  include ActionView::RecordIdentifier

  # POST /admin/pages/:page_id/page_pods
  def create
    page = Page.friendly.find(params[:page_id])
    authorize page, :update?

    pod = Pod.find(params.require(:pod_id))

    next_position = (page.page_pods.maximum(:position) || 0) + 1

    page_pod = page.page_pods.build(pod: pod, position: next_position)

    if page_pod.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "page_pods_list",
              partial: "admin/pages/show_partials/page_pod_row",
              locals: { page: page, pp: page_pod }
            ),
            turbo_stream.remove(dom_id(pod, :available)),
            turbo_stream.remove("page_pods_empty"),
            turbo_stream.update("page_pods_count", "(#{page.page_pods.count})")
          ]
        end
        format.html { redirect_to admin_page_path(page), notice: "Pod added to page." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flash",
            partial: "admin/shared/flash",
            locals: { alert: page_pod.errors.full_messages.to_sentence }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to admin_page_path(page), alert: page_pod.errors.full_messages.to_sentence }
      end
    end
  end

  # PATCH /admin/pages/:page_id/page_pods/sort
  def sort
    page = Page.friendly.find(params[:page_id])
    authorize page, :update?

    ordered_ids = params.require(:ordered_ids)

    ActiveRecord::Base.transaction do
      ordered_ids.each_with_index do |id, index|
        page.page_pods.where(id: id).update_all(position: index + 1)
      end
    end

    render json: { status: "ok" }
  rescue ActionController::ParameterMissing => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  # DELETE /admin/pages/:page_id/page_pods/:id
  def destroy
    page = Page.friendly.find(params[:page_id])
    authorize page, :update?

    page_pod = page.page_pods.find(params[:id])
    pod = page_pod.pod
    page_pod.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(page_pod)),
          turbo_stream.remove("pods_empty"),
          turbo_stream.append(
            "available_pods_grid",
            partial: "admin/pages/show_partials/available_pod_card",
            locals: { page: page, pod: pod }
          ),
          turbo_stream.update("page_pods_count", "(#{page.page_pods.count})")
        ]
      end
      format.html { redirect_to admin_page_path(page), notice: "Pod removed from page." }
    end
  end
end
