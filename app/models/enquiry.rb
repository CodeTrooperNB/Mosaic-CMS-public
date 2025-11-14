# == Schema Information
#
# Table name: enquiries
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :string           not null
#  status     :integer          default("0"), not null
#  spam       :boolean          default("false"), not null
#  form_data  :jsonb            default("{}"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_enquiries_on_created_at  (created_at)
#  index_enquiries_on_email       (email)
#  index_enquiries_on_form_data   (form_data)
#  index_enquiries_on_spam        (spam)
#  index_enquiries_on_status      (status)
#

class Enquiry < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 255 }
  validates :form_data, presence: true
  validate :message_presence_in_form_data

  # Enums
  enum :status, { pending: 0, read: 1, resolved: 2 }, default: :pending, prefix: true

  # Scopes
  scope :not_spam, -> { where(spam: false) }
  scope :spam_items, -> { where(spam: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :search_by_email, ->(email) { where("email ILIKE ?", "%#{sanitize_sql_like(email)}%") if email.present? }
  scope :search_by_name, ->(name) { where("name ILIKE ?", "%#{sanitize_sql_like(name)}%") if name.present? }

  # Callbacks
  before_validation :set_default_form_data

  # Instance methods
  def message
    form_data["message"] || form_data[:message]
  end

  def subject
    form_data["subject"] || form_data[:subject]
  end

  def phone
    form_data["phone"] || form_data[:phone]
  end

  def company
    form_data["company"] || form_data[:company]
  end

  def mark_as_spam!
    update(spam: true)
  end

  def mark_as_not_spam!
    update(spam: false)
  end

  def mark_as_read!
    update(status: :read) if status_pending?
  end

  def mark_as_resolved!
    update(status: :resolved)
  end

  private

  def set_default_form_data
    self.form_data ||= {}
  end

  def message_presence_in_form_data
    return if message.present?

    errors.add(:form_data, "must include a message")
  end
end
