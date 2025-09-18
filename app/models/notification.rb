class Notification < ApplicationRecord
    belongs_to :user
    
    validates :title, :message, :notification_type, presence: true
    
    enum notification_type: { 
      match: 0, 
      bid: 1, 
      shipment: 2, 
      message: 3, 
      payment: 4, 
      system: 5 
    }
    
    scope :unread, -> { where(read_at: nil) }
    scope :recent, -> { order(created_at: :desc) }
  
    def read?
      read_at.present?
    end
  
    def mark_as_read!
      update!(read_at: Time.current) unless read?
    end
  
    after_create_commit :broadcast_notification
    
    private
    
    def broadcast_notification
      ActionCable.server.broadcast(
        "notifications_#{user_id}",
        {
          id: id,
          title: title,
          message: message,
          type: notification_type,
          created_at: created_at.iso8601,
          read: false
        }
      )
    end
  end