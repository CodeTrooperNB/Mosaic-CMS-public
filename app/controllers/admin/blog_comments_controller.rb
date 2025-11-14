# app/controllers/admin/blog_comments_controller.rb
class Admin::BlogCommentsController < Admin::AdminController
  before_action :set_blog_comment

  def update
    authorize @blog_comment

    if @blog_comment.update(comment_params)
      redirect_back fallback_location: admin_blog_path(@blog_comment.blog), notice: "Comment updated."
    else
      redirect_back fallback_location: admin_blog_path(@blog_comment.blog), alert: @blog_comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @blog_comment
    blog = @blog_comment.blog
    @blog_comment.destroy
    redirect_to admin_blog_path(blog), notice: "Comment deleted."
  end

  private

  def set_blog_comment
    @blog_comment = BlogComment.find(params[:id])
  end

  def comment_params
    params.require(:blog_comment).permit(:visible)
  end
end
