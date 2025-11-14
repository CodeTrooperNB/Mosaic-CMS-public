class AddPositionAndAncestryDepthToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :position, :integer
    add_column :pages, :ancestry_depth, :integer, default: 0, null: false
    add_column :pages, :children_count, :integer, default: 0, null: false

    add_index :pages, [:ancestry, :position]
    add_index :pages, :ancestry_depth
    add_index :pages, :children_count
  end
end
