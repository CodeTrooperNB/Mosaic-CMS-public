# app/controllers/admin/admin_users_controller.rb
class Admin::AdminUsersController < Admin::AdminController
  before_action :set_admin_user, only: [:edit, :update, :destroy, :toggle_role]
  before_action :ensure_admin_access

  def index
    @admin_users = policy_scope(AdminUser).order(:email)
    authorize AdminUser
  end

  def new
    @admin_user = AdminUser.new
    authorize @admin_user
  end

  def create
    @admin_user = AdminUser.new(admin_user_params)
    authorize @admin_user

    if @admin_user.save
      redirect_to admin_admin_users_path, notice: "Admin user was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @admin_user
  end

  def update
    authorize @admin_user

    if @admin_user.update(admin_user_params)
      redirect_to admin_admin_users_path, notice: "Admin user was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @admin_user

    if @admin_user == current_admin_user
      redirect_to admin_admin_users_path, alert: "You cannot delete yourself."
    else
      @admin_user.destroy!
      redirect_to admin_admin_users_path, notice: "Admin user was successfully deleted."
    end
  end

  def toggle_role
    authorize @admin_user

    if @admin_user == current_admin_user
      redirect_to admin_admin_users_path, alert: "You cannot change your own role."
    else
      @admin_user.update!(role: @admin_user.admin? ? :editor : :admin)
      redirect_to admin_admin_users_path, notice: "#{@admin_user.display_name}'s role was updated."
    end
  end

  private

  def set_admin_user
    @admin_user = AdminUser.find(params[:id])
  end

  def admin_user_params
    if password_fields_present?
      full_permitted_params
    else
      partial_permitted_params
    end
  end

  def password_fields_present?
    params[:admin_user][:password].present? || params[:admin_user][:password_confirmation].present?
  end

  def full_permitted_params
    params.require(:admin_user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role)
  end

  def partial_permitted_params
    params.require(:admin_user).permit(:first_name, :last_name, :email, :role)
  end

  def ensure_admin_access
    unless current_admin_user.admin?
      flash[:alert] = "You must be an admin to manage users."
      redirect_to admin_root_path
    end
  end
end