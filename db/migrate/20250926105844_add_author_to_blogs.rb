class AddAuthorToBlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :blogs, :author, :string
  end
end
