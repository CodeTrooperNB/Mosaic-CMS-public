class CreateEnquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :enquiries do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :status, default: 0, null: false
      t.boolean :spam, default: false, null: false
      t.jsonb :form_data, default: {}, null: false

      t.timestamps
    end

    add_index :enquiries, :email
    add_index :enquiries, :status
    add_index :enquiries, :spam
    add_index :enquiries, :created_at
    add_index :enquiries, :form_data, using: :gin
  end
end
