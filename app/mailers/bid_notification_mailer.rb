class BidNotificationMailer < ApplicationMailer
    def new_bid(shipment_bid)
      @bid = shipment_bid
      @shipment = shipment_bid.shipment
      @trucker = shipment_bid.trucking_company
      @listing = @shipment.produce_listing
      @farmer = @listing.farmer_profile
      @market = @shipment.produce_request.market_profile
      
      # Send to both farmer and market
      [@farmer.user.email, @market.user.email].each do |email|
        mail(
          to: email,
          subject: "🚛 New shipping bid: $#{@bid.bid_amount} for #{@listing.title}"
        )
      end
    end
  
    def bid_accepted(shipment_bid)
      @bid = shipment_bid
      @shipment = shipment_bid.shipment
      @trucker = shipment_bid.trucking_company
      
      mail(
        to: @trucker.user.email,
        subject: "🎉 Your bid was accepted! Shipment #{@shipment.tracking_number}"
      )
    end
  
    def bid_rejected(shipment_bid)
      @bid = shipment_bid
      @shipment = shipment_bid.shipment
      @trucker = shipment_bid.trucking_company
      
      mail(
        to: @trucker.user.email,
        subject: "Bid update for shipment #{@shipment.tracking_number}"
      )
    end
  end