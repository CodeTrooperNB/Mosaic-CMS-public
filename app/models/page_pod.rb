# == Schema Information
#
# Table name: page_pods
#
#  id                 :integer          not null, primary key
#  page_id            :integer          not null
#  pod_id             :integer          not null
#  ancestry           :string
#  position           :integer
#  page_specific_data :jsonb            default("{}"), not null
#  visible            :boolean          default("true"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_page_pods_on_ancestry              (ancestry)
#  index_page_pods_on_page_id               (page_id)
#  index_page_pods_on_page_id_and_position  (page_id,position)
#  index_page_pods_on_pod_id                (pod_id)
#

class PagePod < ApplicationRecord
  # Flat ordering of pods within a page using the `position` column
  acts_as_list scope: :page_id

  # auditing
  has_paper_trail except: %i[ update ]

  # Associations
  belongs_to :page
  # Track how many pages reference a given pod for reuse insights
  belongs_to :pod, counter_cache: :usage_count

  # Scopes
  scope :ordered_by_position, -> { order(:position) }
  scope :visible, -> { where(draft: true) }

  # Validations
  validates :position, numericality: { only_integer: true }, allow_nil: true

  # JSONB defaults safety
  attribute :page_specific_data, :jsonb, default: {}

  # Convenience: combine base pod content with any page-specific overrides
  # Note: overrides win when keys collide
  def merged_definition
    (pod.definition || {}).deep_merge(page_specific_data || {})
  end
end
