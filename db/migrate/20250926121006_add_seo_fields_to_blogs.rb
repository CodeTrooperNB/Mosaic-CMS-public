class AddSeoFieldsToBlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :blogs, :seo_title, :string
    add_column :blogs, :seo_description, :text
  end
end
