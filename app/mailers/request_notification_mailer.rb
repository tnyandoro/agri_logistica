class RequestNotificationMailer < ApplicationMailer
    def new_request(produce_request)
      @request = produce_request
      @listing = produce_request.produce_listing
      @farmer = @listing.farmer_profile
      @market = produce_request.market_profile
      
      mail(
        to: @farmer.user.email,
        subject: "📦 New purchase request for #{@listing.title}"
      )
    end
  
    def request_accepted(produce_request)
      @request = produce_request
      @listing = produce_request.produce_listing
      @farmer = @listing.farmer_profile
      @market = produce_request.market_profile
      @shipment = produce_request.shipment
      
      mail(
        to: @market.user.email,
        subject: "✅ Your request for #{@listing.title} was accepted!"
      )
    end
  
    def request_rejected(produce_request)
      @request = produce_request
      @listing = produce_request.produce_listing
      @farmer = @listing.farmer_profile
      @market = produce_request.market_profile
      
      mail(
        to: @market.user.email,
        subject: "❌ Request declined: #{@listing.title}"
      )
    end
  end