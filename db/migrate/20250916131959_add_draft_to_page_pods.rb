class AddDraftToPagePods < ActiveRecord::Migration[8.0]
  def change
    add_column :page_pods, :draft, :boolean, default: true, null: false
    add_index :page_pods, [:page_id, :draft]
  end
end
