# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user&.admin? || user&.editor?
  end

  def show?
    user&.admin? || user&.editor?
  end

  def create?
    user&.admin? || user&.editor?
  end

  def new?
    create?
  end

  def update?
    user&.admin? || (user&.editor? && owned_by_user?)
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  private

  def owned_by_user?
    # Override in specific policies if records have an admin_user association
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.admin?
        scope.all
      elsif user&.editor?
        scope.all # Editors can see all for now, override in specific policies
      else
        scope.none
      end
    end

    private

    attr_reader :user, :scope
  end
end