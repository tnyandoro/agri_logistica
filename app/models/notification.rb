class Notification < ApplicationRecord
  belongs_to :user
  
  validates :title, :message, :notification_type, presence: true
  
  enum :notification_type, {
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

  after_create_commit :broadcast_notification, unless: :skip_broadcast?
  
  private
  
  def skip_broadcast?
    # Skip broadcasting during seed/rake tasks or if Redis isn't available
    (defined?(Rake) && Rake.application.top_level_tasks.any?) || Rails.env.test?
  end
  
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
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast notification: #{e.message}"
  end
end