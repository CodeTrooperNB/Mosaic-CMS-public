# == Schema Information
#
# Table name: pods
#
#  id          :integer          not null, primary key
#  pod_type    :string           not null
#  definition  :jsonb            default("{}"), not null
#  reusable    :boolean          default("true"), not null
#  usage_count :integer          default("0"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_pods_on_definition  (definition)
#  index_pods_on_pod_type    (pod_type)
#

class Pod < ApplicationRecord

  # auditing
  has_paper_trail

  # Keep the has_many_attached for automatic cleanup, but use it differently
  has_many_attached :images

  # Associations
  has_many :page_pods, dependent: :destroy
  has_many :pages, through: :page_pods

  # Validations
  validates :name, presence: true
  validates :pod_type, presence: true
  validate :pod_type_is_defined

  # JSONB column default handling safety
  attribute :definition, :jsonb, default: {}

  # Registry helpers
  def schema
    Admin::PodSchemas.schema_for(pod_type)
  end

  # Get attachment by attachment key from any field in the definition
  def attachment_for_key(attachment_key)
    ActiveStorage::Attachment.find_by(record: self, name: attachment_key)
  end

  # Get attachment for a specific field by looking up its attachment_key
  def attachment_for(field_name)
    field_data = definition[field_name]
    return nil unless field_data.is_a?(Hash) && field_data["attachment_key"].present?

    attachment_for_key(field_data["attachment_key"])
  end

  # Get all field-specific attachments (excludes the generic 'images' attachments)
  def field_attachments
    attachment_keys = []

    # Collect all attachment keys from the definition
    definition.each do |field_name, field_data|
      if field_data.is_a?(Hash) && field_data["attachment_key"].present?
        attachment_keys << field_data["attachment_key"]
      end
    end

    ActiveStorage::Attachment.where(record: self, name: attachment_keys)
  end

  # Helper method to get attachment URL for a field with variant support
  def attachment_url_for(field_name, variant: "original")
    field_data = definition[field_name]
    return nil unless field_data.is_a?(Hash) && field_data["attachment_key"].present?

    attachment_key = field_data["attachment_key"]

    if variant == "original"
      "/admin/image_attachments/#{attachment_key}/original"
    else
      "/admin/image_attachments/#{attachment_key}/#{variant}"
    end
  end

  # Helper method to get attachment metadata for a field
  def attachment_metadata_for(field_name)
    field_data = definition[field_name]
    return nil unless field_data.is_a?(Hash)

    {
      attachment_key: field_data["attachment_key"],
      alt_text: field_data["alt_text"],
      filename: field_data["filename"],
      content_type: field_data["content_type"],
      byte_size: field_data["byte_size"],
      uploaded_at: field_data["uploaded_at"]
    }
  end

  def fields(field_key)
    definition.dig(field_key) || {}
  end

  def title
    name.presence || pod_type
  end

  def description
    pod_type.humanize
  end

  private

  def pod_type_is_defined
    return if pod_type.blank?
    types = Admin::PodSchemas.available_types
    unless types.include?(pod_type)
      errors.add(:pod_type, "is not defined in pod_schemas (#{pod_type})")
    end
  rescue => e
    # If registry fails to load, surface a helpful message but do not hard-crash validation
    errors.add(:base, "PodSchemas load error: #{e.class}: #{e.message}")
  end
end
