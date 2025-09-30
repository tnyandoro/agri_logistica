class ShipmentTrackingJob < ApplicationJob
    queue_as :default
  
    def perform(shipment_id)
      shipment = Shipment.find(shipment_id)
      
      # Check if shipment is overdue
      if shipment.in_transit? && shipment.delivery_date.present? && shipment.delivery_date < Time.current
        NotificationService.notify_of_shipment_status(shipment, 'overdue')
      end
      
      # Schedule next check if shipment is still active
      if shipment.status.in?(['pickup_scheduled', 'in_transit'])
        ShipmentTrackingJob.set(wait: 1.hour).perform_later(shipment_id)
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "ShipmentTrackingJob failed: #{e.message}"
    end
  end