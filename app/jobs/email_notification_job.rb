class EmailNotificationJob < ApplicationJob
  queue_as :mailers
  
  def perform(user_id, notification_type, data = {})
    user = User.find(user_id)
    
    case notification_type
    when 'welcome'
      UserMailer.welcome_email(user).deliver_now
    when 'request_notification'
      produce_request = ProduceRequest.find(data['produce_request_id'])
      RequestNotificationMailer.new_request(produce_request).deliver_now
    when 'bid_notification'
      shipment_bid = ShipmentBid.find(data['shipment_bid_id'])
      BidNotificationMailer.new_bid(shipment_bid).deliver_now
    when 'shipment_update'
      shipment = Shipment.find(data['shipment_id'])
      ShipmentMailer.status_update(shipment, user).deliver_now
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "EmailNotificationJob failed: #{e.message}"
  end
end