class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :phone, :string, null: false
    add_column :users, :verified, :boolean, default: false
    
    add_index :users, :phone, unique: true
    add_index :users, :role
  end
end
