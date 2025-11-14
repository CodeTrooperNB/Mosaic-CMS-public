class CreateBlogTags < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_tags do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :blog_tags, :slug, unique: true
    add_index :blog_tags, :name, unique: true
  end
end
