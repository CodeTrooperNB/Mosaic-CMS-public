class CreatePagePods < ActiveRecord::Migration[7.2]
  def change
    create_table :page_pods do |t|
      t.references :page, null: false, foreign_key: true
      t.references :pod, null: false, foreign_key: true
      t.string :ancestry
      t.integer :position
      t.jsonb :page_specific_data, null: false, default: {}
      t.boolean :visible, null: false, default: true
      t.timestamps
    end

    add_index :page_pods, :ancestry
    add_index :page_pods, [:page_id, :position]
  end
end
