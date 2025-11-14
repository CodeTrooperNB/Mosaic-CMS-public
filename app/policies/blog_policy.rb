# app/policies/blog_policy.rb
class BlogPolicy < ApplicationPolicy
  def owned_by_user?
    record.admin_user_id == user&.id
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
