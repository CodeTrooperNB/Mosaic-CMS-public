# == Schema Information
#
# Table name: blogs
#
#  id               :integer          not null, primary key
#  title            :string           not null
#  slug             :string           not null
#  excerpt          :text
#  visible          :boolean          default("false"), not null
#  published_at     :datetime
#  admin_user_id    :integer          not null
#  blog_category_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  author           :string
#  seo_title        :string
#  seo_description  :text
#
# Indexes
#
#  index_blogs_on_admin_user_id     (admin_user_id)
#  index_blogs_on_blog_category_id  (blog_category_id)
#  index_blogs_on_published_at      (published_at)
#  index_blogs_on_slug              (slug) UNIQUE
#  index_blogs_on_visible           (visible)
#

class Blog < ApplicationRecord
  attr_accessor :new_category_name, :new_tag_names, :remove_cover_image

  belongs_to :admin_user
  belongs_to :blog_category

  has_many :blog_taggings, dependent: :destroy
  has_many :blog_tags, through: :blog_taggings
  has_many :blog_comments, dependent: :destroy

  has_one_attached :cover_image

  has_rich_text :content

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :blog_category, presence: true
  validate :content_presence
  validate :cover_image_format
  validates :seo_title, length: { maximum: 180 }, allow_blank: true
  validates :seo_description, length: { maximum: 320 }, allow_blank: true

  delegate :name, to: :blog_category, prefix: true, allow_nil: true

  scope :visible, -> { where(visible: true) }
  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :scheduled, -> { where.not(published_at: nil).where("published_at > ?", Time.current) }
  scope :ordered, -> { order(published_at: :desc, created_at: :desc) }

  scope :latest, -> { order(published_at: :desc).limit(3) }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_save :ensure_published_at

  def published?
    published_at.present? && published_at <= Time.current
  end

  def scheduled?
    published_at.present? && published_at > Time.current
  end

  def displayable?
    visible? && published?
  end

  def to_param
    slug
  end

  def author_name
    return author if author.present?

    [ admin_user&.first_name, admin_user&.last_name ].compact_blank.join(" ")
  end

  def visible_comments
    blog_comments.visible.recent_first
  end

  def display_title
    seo_title.presence || title
  end

  def meta_description
    seo_description.presence || excerpt.presence || content_plain_text&.truncate(160, separator: " ") || ""
  end

  def content_plain_text
    return unless content.respond_to?(:body)

    content.body.to_plain_text
  end

  # Returns an ActiveStorage variant suited for the requested context
  def cover_image_variant(size = :default)
    return unless cover_image.attached?

    transformations = case size
                      when :card
                        { resize_to_fill: [ 640, 400 ] }
                      when :thumb
                        { resize_to_fill: [ 320, 200 ] }
                      when :hero
                        { resize_to_fill: [ 1600, 900 ] }
                      else
                        { resize_to_fill: [ 1200, 630 ] }
                      end

    variant = cover_image.variant(transformations.merge(format: :webp, saver: { quality: 85 }))
    processed_variant = variant.processed
    variant_key = processed_variant.key
    # Direct Bunny CDN URL using Settings.bunny.cdn
    "#{Settings.bunny.cdn}/#{variant_key}"
  rescue ActiveStorage::Error
    cover_image
  end

  private

  def generate_slug
    base_slug = title.to_s.parameterize
    candidate = base_slug
    counter = 2

    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end

  def content_presence
    plain_text = content_plain_text.to_s
    return if plain_text.squish.present?

    errors.add(:content, "can't be blank")
  end

  def ensure_published_at
    self.published_at ||= Time.current
  end

  def cover_image_format
    return unless cover_image.attached?

    acceptable_types = %w[image/png image/jpg image/jpeg image/webp image/avif]
    unless acceptable_types.include?(cover_image.content_type)
      errors.add(:cover_image, "must be a PNG, JPG, WebP, or AVIF file")
      return
    end

    if cover_image.byte_size > 10.megabytes
      errors.add(:cover_image, "must be smaller than 10 MB")
    end
  end
end
