# == Schema Information
#
# Table name: blog_taggings
#
#  id          :integer          not null, primary key
#  blog_id     :integer          not null
#  blog_tag_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_blog_taggings_on_blog_id                  (blog_id)
#  index_blog_taggings_on_blog_id_and_blog_tag_id  (blog_id,blog_tag_id) UNIQUE
#  index_blog_taggings_on_blog_tag_id              (blog_tag_id)
#

class BlogTagging < ApplicationRecord
  belongs_to :blog
  belongs_to :blog_tag

  validates :blog_tag_id, uniqueness: { scope: :blog_id }
end
