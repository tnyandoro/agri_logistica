class RenameRoleInUsers < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :role, :user_role
  end
end
