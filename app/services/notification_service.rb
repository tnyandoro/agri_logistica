class NotificationService
    class << self
      def notify_farmer_of_request(produce_request)
        farmer = produce_request.produce_listing.farmer_profile.user
        market_name = produce_request.market_profile.market_name
        
        create_notification(
          user: farmer,
          title: "New purchase request",
          message: "#{market_name} wants to buy #{produce_request.quantity} #{produce_request.produce_listing.unit} of #{produce_request.produce_listing.title}",
          notification_type: :match,
          data: {
            produce_request_id: produce_request.id,
            produce_listing_id: produce_request.produce_listing.id
          }
        )
        
        # Send email notification
        RequestNotificationMailer.new_request(produce_request).deliver_later
      end
  
      def notify_market_of_acceptance(produce_request)
        market = produce_request.market_profile.user
        farm_name = produce_request.produce_listing.farmer_profile.farm_name
        
        create_notification(
          user: market,
          title: "Request accepted!",
          message: "#{farm_name} accepted your request for #{produce_request.produce_listing.title}. Shipment will be arranged.",
          notification_type: :match,
          data: {
            produce_request_id: produce_request.id,
            shipment_id: produce_request.shipment&.id
          }
        )
      end
  
      def notify_market_of_rejection(produce_request)
        market = produce_request.market_profile.user
        farm_name = produce_request.produce_listing.farmer_profile.farm_name
        
        create_notification(
          user: market,
          title: "Request declined",
          message: "#{farm_name} declined your request for #{produce_request.produce_listing.title}",
          notification_type: :match,
          data: { produce_request_id: produce_request.id }
        )
      end
  
      def notify_of_new_shipment_bid(shipment_bid)
        # Notify both farmer and market of new bid
        shipment = shipment_bid.shipment
        trucker_name = shipment_bid.trucking_company.company_name
        
        [shipment.farmer, shipment.market].each do |user|
          create_notification(
            user: user,
            title: "New shipping bid",
            message: "#{trucker_name} bid $#{shipment_bid.bid_amount} for shipment #{shipment.tracking_number}",
            notification_type: :bid,
            data: {
              shipment_id: shipment.id,
              shipment_bid_id: shipment_bid.id
            }
          )
        end
      end
  
      def notify_of_bid_acceptance(shipment_bid)
        trucker = shipment_bid.trucking_company.user
        
        create_notification(
          user: trucker,
          title: "Bid accepted!",
          message: "Your bid of $#{shipment_bid.bid_amount} was accepted. Pickup scheduled for #{shipment_bid.pickup_time&.strftime('%B %d, %Y')}",
          notification_type: :bid,
          data: {
            shipment_id: shipment_bid.shipment.id,
            shipment_bid_id: shipment_bid.id
          }
        )
      end
  
      def notify_of_shipment_status(shipment, new_status)
        users_to_notify = [shipment.farmer, shipment.market]
        users_to_notify << shipment.trucking_company.user if shipment.trucking_company
        
        status_messages = {
          'pickup_scheduled' => 'Pickup has been scheduled',
          'in_transit' => 'Your shipment is now in transit',
          'delivered' => 'Your shipment has been delivered',
          'cancelled' => 'Shipment has been cancelled'
        }
        
        message = status_messages[new_status] || "Shipment status updated to #{new_status}"
        
        users_to_notify.each do |user|
          create_notification(
            user: user,
            title: "Shipment update",
            message: "#{message} - Tracking: #{shipment.tracking_number}",
            notification_type: :shipment,
            data: { shipment_id: shipment.id }
          )
        end
      end
  
      def notify_markets_of_new_listing(produce_listing)
        # Find markets that might be interested in this produce
        interested_markets = MarketProfile.joins(:user)
                                         .where(
                                           'preferred_produces @> ARRAY[?]::text[]', 
                                           produce_listing.produce_type
                                         )
        
        interested_markets.find_each do |market|
          # Calculate if this listing is within reasonable distance
          next unless within_reasonable_distance?(market, produce_listing.farmer_profile)
          
          create_notification(
            user: market.user,
            title: "New matching produce available",
            message: "#{produce_listing.farmer_profile.farm_name} listed #{produce_listing.quantity} #{produce_listing.unit} of #{produce_listing.title}",
            notification_type: :match,
            data: { produce_listing_id: produce_listing.id }
          )
        end
      end
  
      private
  
      def create_notification(user:, title:, message:, notification_type:, data: {})
        Notification.create!(
          user: user,
          title: title,
          message: message,
          notification_type: notification_type,
          data: data
        )
      end
  
      def within_reasonable_distance?(market, farmer, max_distance = 200)
        return true unless market.latitude && farmer.latitude
        
        # Calculate distance using Haversine formula
        distance = calculate_distance(
          market.latitude, market.longitude,
          farmer.latitude, farmer.longitude
        )
        
        distance <= max_distance
      end
  
      def calculate_distance(lat1, lng1, lat2, lng2)
        rad_per_deg = Math::PI / 180
        rlat1, rlng1, rlat2, rlng2 = [lat1, lng1, lat2, lng2].map { |d| d * rad_per_deg }
        
        dlat = rlat2 - rlat1
        dlng = rlng2 - rlng1
        
        a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        
        6371 * c  # Earth's radius in kilometers
      end
    end
  end