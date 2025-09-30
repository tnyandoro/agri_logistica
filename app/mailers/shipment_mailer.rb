class ShipmentMailer < ApplicationMailer
    def status_update(shipment, user)
      @shipment = shipment
      @user = user
      @listing = shipment.produce_listing
      @status_message = status_message_for(@shipment.status)
      
      mail(
        to: user.email,
        subject: "📦 Shipment Update: #{@shipment.tracking_number} - #{@shipment.status.humanize}"
      )
    end
  
    def pickup_reminder(shipment)
      return unless shipment.trucking_company
  
      @shipment = shipment
      @trucker = shipment.trucking_company
      @pickup_time = shipment.pickup_date
      
      mail(
        to: @trucker.user.email,
        subject: "⏰ Pickup reminder: #{@shipment.tracking_number} tomorrow"
      )
    end
  
    def delivery_confirmation(shipment)
      @shipment = shipment
      @listing = shipment.produce_listing
      @farmer = @listing.farmer_profile
      @market = shipment.produce_request.market_profile
      
      [@farmer.user.email, @market.user.email].each do |email|
        mail(
          to: email,
          subject: "✅ Delivered: #{@listing.title} - #{@shipment.tracking_number}"
        )
      end
    end
  
    private
  
    def status_message_for(status)
      case status
      when 'pickup_scheduled'
        'Your shipment pickup has been scheduled'
      when 'in_transit'
        'Your shipment is now on its way'
      when 'delivered'
        'Your shipment has been successfully delivered'
      when 'cancelled'
        'Your shipment has been cancelled'
      else
        "Your shipment status has been updated to #{status.humanize}"
      end
    end
  end
end