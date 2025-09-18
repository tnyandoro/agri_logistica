class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :message, null: false
      t.integer :notification_type, null: false, default: 0
      t.datetime :read_at
      t.json :data, default: {}

      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, :notification_type
    add_index :notifications, :created_at
  end
end
