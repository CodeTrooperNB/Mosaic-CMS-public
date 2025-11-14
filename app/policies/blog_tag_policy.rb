# app/policies/blog_tag_policy.rb
class BlogTagPolicy < ApplicationPolicy
  def update?
    user&.admin? || user&.editor?
  end

  def destroy?
    user&.admin?
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
