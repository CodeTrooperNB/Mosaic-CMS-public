class CreatePods < ActiveRecord::Migration[7.2]
  def change
    create_table :pods do |t|
      t.string :pod_type, null: false
      t.jsonb :definition, null: false, default: {}
      t.boolean :reusable, null: false, default: true
      t.integer :usage_count, null: false, default: 0
      t.timestamps
    end

    add_index :pods, :pod_type
    add_index :pods, :definition, using: :gin
  end
end
