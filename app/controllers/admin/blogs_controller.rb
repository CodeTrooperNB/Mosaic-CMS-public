# app/controllers/admin/blogs_controller.rb
class Admin::BlogsController < Admin::AdminController
  before_action :set_blog, only: [:show, :edit, :update, :destroy]

  def index
    authorize Blog

    @blog_categories = BlogCategory.all
    @blog_tags = BlogTag.alphabetical

    base_scope = policy_scope(Blog)

    @stats = {
      total: base_scope.count,
      visible: base_scope.where(visible: true).count,
      published: base_scope.visible.published.count,
      scheduled: base_scope.visible.scheduled.count
    }

    @blogs = base_scope.includes(:blog_category, :blog_tags, :admin_user)
    @blogs = filter_by_category(@blogs)
    @blogs = filter_by_tag(@blogs)
    @blogs = filter_by_visibility(@blogs)
    @blogs = filter_by_schedule(@blogs)
    @blogs = @blogs.distinct.ordered
  end

  def show
    authorize @blog
    @comments = @blog.blog_comments.order(created_at: :desc)
  end

  def new
    @blog = Blog.new(visible: false)
    authorize @blog
    load_supporting_data
  end

  def edit
    authorize @blog
    load_supporting_data
  end

  def create
    @blog = Blog.new(blog_params)
    @blog.admin_user = current_admin_user
    authorize @blog

    apply_new_taxonomy_inputs(@blog)

    if @blog.save
      redirect_to admin_blog_path(@blog), notice: "Blog post created successfully."
    else
      load_supporting_data
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @blog

    @blog.assign_attributes(blog_params)
    apply_new_taxonomy_inputs(@blog)

    if @blog.save
      redirect_to admin_blog_path(@blog), notice: "Blog post updated successfully."
    else
      load_supporting_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @blog
    @blog.destroy
    redirect_to admin_blogs_path, notice: "Blog post deleted."
  end

  private

  def set_blog
    @blog = Blog.find_by(slug: params[:id])
    @blog ||= Blog.find(params[:id])
  end

  def load_supporting_data
    @blog_categories = BlogCategory.all
    @blog_tags = BlogTag.alphabetical
  end

  def blog_params
    permitted = params.require(:blog).permit(:title, :slug, :excerpt, :content, :author, :seo_title, :seo_description,
                                             :visible, :published_at, :blog_category_id,
                                             :new_category_name, :new_tag_names, :cover_image,
                                             blog_tag_ids: [])
    permitted[:blog_tag_ids]&.reject!(&:blank?)
    permitted[:published_at] = nil if permitted[:published_at].blank?
    permitted
  end

  def filter_by_category(scope)
    return scope unless params[:category].present?

    category = BlogCategory.find_by(slug: params[:category]) || BlogCategory.find_by(id: params[:category])
    category ? scope.where(blog_category_id: category.id) : scope.none
  end

  def filter_by_tag(scope)
    return scope unless params[:tag].present?

    tag = BlogTag.find_by(slug: params[:tag]) || BlogTag.find_by(id: params[:tag])
    tag ? scope.joins(:blog_tags).where(blog_tags: { id: tag.id }) : scope.none
  end

  def filter_by_visibility(scope)
    return scope unless params[:visible].present?

    case params[:visible]
    when "true"
      scope.where(visible: true)
    when "false"
      scope.where(visible: false)
    else
      scope
    end
  end

  def filter_by_schedule(scope)
    return scope unless params[:schedule].present?

    case params[:schedule]
    when "published"
      scope.published
    when "scheduled"
      scope.scheduled
    else
      scope
    end
  end

  def apply_new_taxonomy_inputs(blog)
    assign_new_category(blog)
    assign_new_tags(blog)
  end

  def assign_new_category(blog)
    name = blog.new_category_name.to_s.strip
    return if name.blank?

    category = BlogCategory.where("LOWER(name) = ?", name.downcase).first
    category ||= BlogCategory.new(name: name, description: "")

    if category.new_record?
      unless category.save
        category.errors.full_messages.each do |message|
          blog.errors.add(:base, "Category error: #{message}")
        end
        return
      end
    end

    blog.blog_category = category
  end

  def assign_new_tags(blog)
    raw_names = blog.new_tag_names.to_s.split(/[,\n]/).map { |value| value.strip }.reject(&:blank?)
    return if raw_names.empty?

    downcased = raw_names.map(&:downcase)
    existing_tags = BlogTag.where("LOWER(name) IN (?)", downcased)

    remaining_names = raw_names.reject do |name|
      existing_tags.any? { |tag| tag.name.casecmp?(name) }
    end

    new_tags = remaining_names.filter_map do |name|
      tag = BlogTag.new(name: name)
      if tag.save
        tag
      else
        tag.errors.full_messages.each do |message|
          blog.errors.add(:base, "Tag error for '#{name}': #{message}")
        end
        nil
      end
    end

    blog.blog_tags = (blog.blog_tags + existing_tags + new_tags).uniq
  end
end
