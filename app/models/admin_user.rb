# == Schema Information
#
# Table name: admin_users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string           not null
#  last_name              :string           not null
#  role                   :integer          default("0"), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  failed_attempts        :integer          default("0"), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_admin_users_on_role                  (role)
#  index_admin_users_on_unlock_token          (unlock_token) UNIQUE
#

class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # auditing
  has_paper_trail

  enum :role, {
    editor: 0,
    admin: 1
  }

  validates :role, presence: true
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Default role for new users
  after_initialize :set_default_role, if: :new_record?

  # Scopes for different roles
  scope :admins, -> { where(role: :admin) }
  scope :editors, -> { where(role: :editor) }

  # Role helpers
  def admin?
    role == "admin"
  end

  def editor?
    role == "editor"
  end

  def display_name
    email.split("@").first.humanize
  end

  def name
    "#{first_name} #{last_name}"
  end

  private

  def set_default_role
    self.role ||= :editor
  end
end
