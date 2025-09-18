class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer
    add_column :users, :phone, :string
    add_column :users, :verified, :boolean
  end
end
