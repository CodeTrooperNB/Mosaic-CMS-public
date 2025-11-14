# app/controllers/admin/application_controller.rb
class Admin::AdminController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization
  include Admin::SvgHelper
  include BunnyImageHelper
  include PodImageHelper

  before_action :authenticate_admin_user!
  before_action :ensure_admin_access
  before_action :set_paper_trail_whodunnit

  layout "admin/admin"

  protected

  def user_for_paper_trail
    signed_in? ? current_admin_user.id : "System"
  end

  def ensure_admin_access
    redirect_to "/admin/auth/sign_in" unless current_admin_user&.admin? || current_admin_user&.editor?
  end

  def pundit_user
    current_admin_user
  end

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError do |exception|
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = "You are not authorized to perform this action on #{policy_name.gsub('_policy', '')}."
    redirect_to(request.referrer || admin_root_path)
  end

  private

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end