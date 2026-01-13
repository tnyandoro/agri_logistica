class AddPolymorphicToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :notifications, :notifiable, polymorphic: true, index: true
  end
end