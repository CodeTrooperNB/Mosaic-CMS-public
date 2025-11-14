# app/controllers/admin/registrations_controller.rb
class Admin::Devise::RegistrationsController < Devise::RegistrationsController
  layout "admin/auth"

  before_action :ensure_admin_access, except: [:edit, :update]

  protected

  def after_sign_up_path_for(resource)
    admin_root_path
  end

  def after_update_path_for(resource)
    admin_root_path
  end

  private

  def ensure_admin_access
    unless current_admin_user&.admin?
      flash[:alert] = "You must be an admin to register new users."
      redirect_to admin_root_path
    end
  end
end