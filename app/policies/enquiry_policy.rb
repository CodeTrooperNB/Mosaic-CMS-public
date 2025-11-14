# app/policies/enquiry_policy.rb
class EnquiryPolicy < ApplicationPolicy
  def index?
    user&.admin? || user&.editor?
  end

  def show?
    user&.admin? || user&.editor?
  end

  def destroy?
    user&.admin?
  end

  def mark_as_read?
    user&.admin? || user&.editor?
  end

  def mark_as_resolved?
    user&.admin? || user&.editor?
  end

  def mark_as_spam?
    user&.admin? || user&.editor?
  end

  def mark_as_not_spam?
    user&.admin? || user&.editor?
  end

  def clear_spam?
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
