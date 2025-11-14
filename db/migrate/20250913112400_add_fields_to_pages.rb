class AddFieldsToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :menu_title, :string
    add_column :pages, :show_in_menu, :boolean, default: true, null: false
    add_column :pages, :skip_to_first_child, :boolean, default: false, null: false
    add_column :pages, :show_in_footer, :boolean, default: false, null: false
    add_column :pages, :view_template, :string
    add_column :pages, :redirect_path, :string

    add_index :pages, :show_in_menu
    add_index :pages, :show_in_footer
  end
end