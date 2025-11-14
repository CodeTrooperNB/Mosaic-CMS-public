# app/controllers/admin/pages_controller.rb
class Admin::PagesController < Admin::AdminController
  def index
    @stats = {
      total_pages: Page.count,
      published_pages: Page.published.count,
      draft_pages: Page.where(published: false).count
    }

    # Order by position within each ancestry level
    all_pages = Page.order(:ancestry, :position)
    @pages_by_parent = all_pages.group_by(&:parent_id)
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(page_params)

    if @page.save
      redirect_to admin_page_path(@page), notice: "Page created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @page = Page.friendly.find(params[:id])
    @page_pods = @page.page_pods.includes(:pod).order(:position)
    # Only show pods that are not already linked to this page
    @available_pods = Pod.where.not(id: @page.pod_ids).order(:pod_type)
  end

  def edit
    @page = Page.friendly.find(params[:id])
  end

  def update
    @page = Page.friendly.find(params[:id])

    if @page.update(page_params)
      redirect_to admin_page_path(@page), notice: "Page updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_hierarchy
    @page = Page.friendly.find(params[:id])
    ancestry_id = params[:parent_id]
    position = params[:position]

    Rails.logger.info "Updating page #{@page.id} hierarchy - Ancestry ID: #{ancestry_id}, Position: #{position}"

    begin
      # Store the old ancestry for comparison
      old_ancestry = @page.ancestry

      # Handle ancestry logic like in your working app
      if ancestry_id == "undefined" || ancestry_id.nil? || ancestry_id.blank?
        new_ancestry = nil
      else
        ancestor = Page.find_by(id: ancestry_id)
        if ancestor.present?
          new_ancestry = ancestor.ancestry.present? ? "#{ancestor.ancestry}/#{ancestry_id}" : "#{ancestry_id}"
        else
          new_ancestry = nil
        end
      end

      # If ancestry changed, we need to handle the scope change for acts_as_list
      if old_ancestry != new_ancestry
        # Remove from current list position
        @page.remove_from_list

        # Update ancestry
        @page.update!(ancestry: new_ancestry)

        # Insert at the new position in the new scope
        @page.insert_at(position.to_i) if position.present?
      else
        # Same ancestry, just update position
        @page.insert_at(position.to_i) if position.present?
      end

      Rails.logger.info "Successfully updated page #{@page.id} ancestry to '#{@page.ancestry}' at position #{@page.position}"
      render json: { status: "success", message: "Page hierarchy updated" }
    rescue => e
      Rails.logger.error "Failed to update page #{@page.id} hierarchy: #{e.message}"
      render json: { status: "error", message: e.message }, status: :unprocessable_entity
    end
  end

  def destroy
    page = Page.friendly.find(params[:id])

    ActiveRecord::Base.transaction do
      # Move children up one level before deleting parent
      page.children.each do |child|
        child.update!(parent_id: page.parent_id)
      end

      page.destroy!
    end

    redirect_to admin_pages_path, notice: "Page deleted. Child pages have been moved up one level."
  end

  private

  def page_params
    params.require(:page).permit(
      :title,
      :slug,
      :meta_description,
      :published,
      :published_at,
      :parent_id,
      :position,
      :menu_title,
      :show_in_menu,
      :skip_to_first_child,
      :show_in_footer,
      :view_template,
      :redirect_path
    )
  end
end