class CleanupJob < ApplicationJob
    queue_as :default
  
    def perform
      # Clean up old notifications (older than 30 days)
      Notification.where('created_at < ?', 30.days.ago).delete_all
      
      # Clean up cancelled/rejected requests older than 7 days
      ProduceRequest.where(status: [:cancelled, :rejected])
                    .where('updated_at < ?', 7.days.ago)
                    .delete_all
      
      # Clean up old expired listings
      ProduceListing.where(status: :expired)
                    .where('available_until < ?', 30.days.ago)
                    .delete_all
      
      # Clean up old shipment bids that weren't accepted
      ShipmentBid.where(status: [:rejected, :cancelled])
                 .where('created_at < ?', 14.days.ago)
                 .delete_all
      
      Rails.logger.info "CleanupJob completed successfully"
    end
  end