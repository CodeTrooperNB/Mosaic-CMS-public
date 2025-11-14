class CreatePages < ActiveRecord::Migration[7.2]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :meta_description
      t.boolean :published, null: false, default: false
      t.datetime :published_at
      t.string :ancestry
      t.timestamps
    end

    add_index :pages, :slug, unique: true
    add_index :pages, :ancestry
  end
end
