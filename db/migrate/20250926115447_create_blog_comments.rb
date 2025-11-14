class CreateBlogComments < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_comments do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :author_name, null: false
      t.string :author_email
      t.text :body, null: false
      t.boolean :visible, null: false, default: true

      t.timestamps
    end
    add_index :blog_comments, :visible
    add_index :blog_comments, :created_at
  end
end
