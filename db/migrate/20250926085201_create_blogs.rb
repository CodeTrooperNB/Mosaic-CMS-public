class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.boolean :visible, null: false, default: false
      t.datetime :published_at
      t.references :admin_user, null: false, foreign_key: true
      t.references :blog_category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :blogs, :slug, unique: true
    add_index :blogs, :published_at
    add_index :blogs, :visible
  end
end
