class CreateBlogTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_taggings do |t|
      t.references :blog, null: false, foreign_key: true
      t.references :blog_tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :blog_taggings, [:blog_id, :blog_tag_id], unique: true
  end
end
