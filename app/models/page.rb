# == Schema Information
#
# Table name: pages
#
#  id                  :integer          not null, primary key
#  title               :string           not null
#  slug                :string           not null
#  meta_description    :text
#  published           :boolean          default("false"), not null
#  published_at        :datetime
#  ancestry            :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  position            :integer
#  ancestry_depth      :integer          default("0"), not null
#  children_count      :integer          default("0"), not null
#  menu_title          :string
#  show_in_menu        :boolean          default("true"), not null
#  skip_to_first_child :boolean          default("false"), not null
#  show_in_footer      :boolean          default("false"), not null
#  view_template       :string
#  redirect_path       :string
#
# Indexes
#
#  index_pages_on_ancestry               (ancestry)
#  index_pages_on_ancestry_and_position  (ancestry,position)
#  index_pages_on_ancestry_depth         (ancestry_depth)
#  index_pages_on_children_count         (children_count)
#  index_pages_on_show_in_footer         (show_in_footer)
#  index_pages_on_show_in_menu           (show_in_menu)
#  index_pages_on_slug                   (slug) UNIQUE
#

class Page < ApplicationRecord
  extend FriendlyId

  # Hierarchical page structure with positioning
  acts_as_list scope: [:ancestry]
  has_ancestry cache_depth: true, counter_cache: true, orphan_strategy: :adopt

  # auditing
  has_paper_trail

  # Associations
  has_many :page_pods, -> { order(:position) }, dependent: :destroy
  has_many :pods, through: :page_pods

  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  # Scopes
  scope :published, -> { where(published: true) }
  scope :in_menu, -> { where(show_in_menu: true) }
  scope :in_footer, -> { where(show_in_footer: true) }
  scope :ordered, -> { order(:position, :created_at) }

  # Callbacks
  before_save :set_published_at, if: :published_changed?

  # FriendlyID configuration: use title to generate slug when not provided
  friendly_id :title, use: :slugged

  # Only generate a new slug when it's blank or when the title changes and no manual slug provided
  def should_generate_new_friendly_id?
    slug.blank? || (will_save_change_to_title? && self[:slug].blank?)
  end

  def to_param
    slug
  end

  def should_redirect?
    redirect_path.present?
  end

  def is_controller_delegation?
    redirect_path.present? && redirect_path.match?(/\A\w+#\w+\z/)
  end

  def display_title
    menu_title.presence || title
  end

  def set_published_at
    self.published_at = self.published ? Time.zone.now : nil
  end
end
