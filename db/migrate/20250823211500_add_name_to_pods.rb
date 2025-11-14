class AddNameToPods < ActiveRecord::Migration[7.2]
  def change
    add_column :pods, :name, :string, null: false, default: ""
    add_index :pods, :name
  end
end
