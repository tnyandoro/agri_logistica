# app/services/notification_service.rb
class NotificationService
  class << self
    # -----------------------------
    # ProduceRequest notifications
    # -----------------------------
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

      # Email
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

    # -----------------------------
    # Shipment notifications
    # -----------------------------
    def notify_truckers_of_new_shipment(shipment)
      TruckingCompany.all.each do |trucker|
        create_notification(
          user: trucker.user,
          title: "New shipment available",
          message: "Shipment from #{shipment.origin_address} to #{shipment.destination_address}. Distance: #{shipment.distance_km} km. Estimated cost: #{shipment.agreed_price}",
          notification_type: :shipment,
          data: { shipment_id: shipment.id }
        )
      end
    end

    def notify_market_of_shipment_acceptance(shipment)
      market_user = shipment.produce_request.market_profile.user
      create_notification(
        user: market_user,
        title: "Shipment accepted",
        message: "#{shipment.trucking_company.company_name} accepted your shipment for #{shipment.produce_listing.title}.",
        notification_type: :shipment,
        data: { shipment_id: shipment.id }
      )
    end

    def notify_market_of_shipment_cancellation(shipment)
      market_user = shipment.produce_request.market_profile.user
      create_notification(
        user: market_user,
        title: "Shipment cancelled",
        message: "#{shipment.trucking_company.company_name} cancelled shipment for #{shipment.produce_listing.title}.",
        notification_type: :shipment,
        data: { shipment_id: shipment.id }
      )
    end

    # -----------------------------
    # Optional: new bids for shipments
    # -----------------------------
    def notify_of_new_shipment_bid(shipment_bid)
      shipment = shipment_bid.shipment
      trucker_name = shipment_bid.trucking_company.company_name

      [shipment.farmer.user, shipment.produce_request.market_profile.user].each do |user|
        create_notification(
          user: user,
          title: "New shipping bid",
          message: "#{trucker_name} bid $#{shipment_bid.bid_amount} for shipment #{shipment.tracking_number}",
          notification_type: :bid,
          data: { shipment_id: shipment.id, shipment_bid_id: shipment_bid.id }
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
        data: { shipment_id: shipment_bid.shipment.id, shipment_bid_id: shipment_bid.id }
      )
    end

    # -----------------------------
    # Generic notification method
    # -----------------------------
    private

    def create_notification(user:, title:, message:, notification_type:, data: {})
      Notification.create!(
        user: user,
        title: title,
        message: message,
        notification_type: notification_type,
        data: data
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create notification for user #{user.id}: #{e.message}")
    end

    # -----------------------------
    # Optional: distance check for markets
    # -----------------------------
    def within_reasonable_distance?(market, farmer, max_distance = 200)
      return true unless market.latitude && farmer.latitude
      distance = calculate_distance(market.latitude, market.longitude, farmer.latitude, farmer.longitude)
      distance <= max_distance
    end

    def calculate_distance(lat1, lng1, lat2, lng2)
      rad_per_deg = Math::PI / 180
      rlat1, rlng1, rlat2, rlng2 = [lat1, lng1, lat2, lng2].map { |d| d * rad_per_deg }
      dlat = rlat2 - rlat1
      dlng = rlng2 - rlng1
      a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      6371 * c
    end
  end
end
