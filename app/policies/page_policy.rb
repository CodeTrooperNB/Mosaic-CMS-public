# app/policies/page_policy.rb
class PagePolicy < ApplicationPolicy
  # Inherit all defaults from ApplicationPolicy:
  # - admin and editor can index/show/create by default
  # - update/edit allowed for admin, and for editor when owned_by_user? is true
  # - destroy is admin-only
  #
  # This placeholder establishes a concrete policy so Pundit can resolve
  # authorize(page, :update?) in controllers like Admin::PagePodsController.
  #
  # Future Phase 8: implement ancestry-aware permissions (e.g., editors can
  # manage pages within their assigned branch) and customize Scope.

  class Scope < Scope
    def resolve
      super
    end
  end
end