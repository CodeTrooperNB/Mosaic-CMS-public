# == Schema Information
#
# Table name: blog_comments
#
#  id               :integer          not null, primary key
#  blog_id          :integer          not null
#  author_name      :string           not null
#  author_last_name :string
#  body             :text             not null
#  visible          :boolean          default("false"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_blog_comments_on_blog_id     (blog_id)
#  index_blog_comments_on_created_at  (created_at)
#  index_blog_comments_on_visible     (visible)
#

class BlogComment < ApplicationRecord
  belongs_to :blog

  scope :visible, -> { where(visible: true) }
  scope :recent_first, -> { order(created_at: :desc) }

  validates :author_name, presence: true
  validates :body, presence: true
  validates :author_email,
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  def display_name
    author_name.presence || "Anonymous"
  end
end
