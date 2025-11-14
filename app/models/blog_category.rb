# == Schema Information
#
# Table name: blog_categories
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  description :text
#  position    :integer          default("0"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_blog_categories_on_name  (name) UNIQUE
#  index_blog_categories_on_slug  (slug) UNIQUE
#

class BlogCategory < ApplicationRecord
  has_many :blogs, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :assign_position, if: -> { position.blank? }

  default_scope { order(position: :asc, name: :asc) }

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

  def assign_position
    self.position = (self.class.maximum(:position) || -1) + 1
  end
end
