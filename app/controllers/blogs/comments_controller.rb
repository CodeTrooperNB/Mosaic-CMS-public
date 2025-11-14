# app/controllers/blogs/comments_controller.rb
module Blogs
  class CommentsController < ApplicationController
    def create
      @blog = Blog.visible.published.find_by!(slug: params[:blog_id])
      @comment = @blog.blog_comments.new(comment_params)

      if @comment.save
        redirect_to blog_path(@blog, anchor: "comments"), notice: "Thanks for commenting!"
      else
        @comments = @blog.visible_comments
        @seo_resource = @blog
        render "blogs/show", status: :unprocessable_entity
      end
    end

    private

    def comment_params
      params.require(:blog_comment).permit(:author_name, :author_email, :body)
    end
  end
end
