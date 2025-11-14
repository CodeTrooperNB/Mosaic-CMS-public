# app/controllers/admin/passwords_controller.rb
class Admin::Devise::PasswordsController < Devise::PasswordsController
  layout "admin/auth"

  protected

  def after_resetting_password_path_for(resource)
    admin_root_path
  end
end