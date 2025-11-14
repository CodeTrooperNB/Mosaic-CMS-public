# app/policies/blog_comment_policy.rb
class BlogCommentPolicy < ApplicationPolicy
  def update?
    user&.admin? || user&.editor?
  end

  def destroy?
    user&.admin? || user&.editor?
  end

  class Scope < Scope
    def resolve
      if user&.admin? || user&.editor?
        scope.all
      else
        scope.none
      end
    end
  end
end
