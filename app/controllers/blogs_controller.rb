# app/controllers/blogs_controller.rb
class BlogsController < ApplicationController
  before_action :load_filters, only: [:index]

  def index
    @selected_category = find_selected_category
    @selected_tags = find_selected_tags
    @selected_tag_ids = @selected_tags.map(&:id)

    @blogs = Blog.visible.published
                 .includes(:blog_category, :blog_tags)
                 .with_rich_text_content
    @blogs = @blogs.where(blog_category_id: @selected_category.id) if @selected_category
    if @selected_tags.any?
      @blogs = @blogs.joins(:blog_tags).where(blog_tags: { id: @selected_tags.map(&:id) })
    end
    @blogs = @blogs.distinct.ordered
  end

  def show
    scope = Blog.visible.published.with_rich_text_content.includes(:blog_category, :blog_tags)
    @blog = scope.find_by!(slug: params[:id])
    @comment = @blog.blog_comments.new
    @comments = @blog.visible_comments
    @seo_resource = @blog
  end

  private

  def load_filters
    @categories = BlogCategory.all
    @tags = BlogTag.alphabetical
  end

  def find_selected_category
    return unless params[:category].present?

    BlogCategory.find_by(slug: params[:category]) || BlogCategory.find_by(id: params[:category])
  end

  def find_selected_tags
    return [] unless params[:tags].present?

    tag_params = params[:tags]
    tag_ids = Array(tag_params).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:blank?)
    return [] if tag_ids.empty?

    BlogTag.where(slug: tag_ids)
           .or(BlogTag.where(id: tag_ids))
           .distinct
  end
end
