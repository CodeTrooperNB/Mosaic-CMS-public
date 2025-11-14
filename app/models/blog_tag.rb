# == Schema Information
#
# Table name: blog_tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_blog_tags_on_name  (name) UNIQUE
#  index_blog_tags_on_slug  (slug) UNIQUE
#

class BlogTag < ApplicationRecord
  has_many :blog_taggings, dependent: :destroy
  has_many :blogs, through: :blog_taggings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :alphabetical, -> { order(:name) }

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = name.to_s.parameterize
    candidate = base_slug
    counter = 2

    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
