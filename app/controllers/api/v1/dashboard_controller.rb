module Api
  module V1
    class DashboardController < BaseController
      before_action :authenticate_user!

      def index
        case current_user.user_role
        when 'farmer'
          render json: farmer_dashboard, status: :ok
        when 'trucker'
          render json: trucker_dashboard, status: :ok
        when 'market'
          render json: market_dashboard, status: :ok
        else
          render json: { error: 'Invalid user role' }, status: :bad_request
        end
      end

      private

      def farmer_dashboard
        profile = current_user.farmer_profile
        
        return { error: 'Farmer profile not found' } unless profile

        recent_listings = profile.produce_listings.recent.limit(5)
        total_listings = profile.produce_listings.count

        active_requests = ProduceRequest.joins(:produce_listing)
                                       .where(produce_listings: { farmer_profile: profile })
                                       .where(status: :pending)
                                       .count

        total_earnings = ProduceRequest.joins(:produce_listing)
                                      .where(produce_listings: { farmer_profile: profile })
                                      .where(status: :completed)
                                      .sum('produce_requests.quantity * produce_requests.price_offered')

        # Chart data
        produce_summary = profile.produce_listings
                                .group(:produce_type)
                                .sum(:quantity)

        monthly_earnings = ProduceRequest.joins(:produce_listing)
                                        .where(produce_listings: { farmer_profile: profile })
                                        .where(status: :completed)
                                        .where("produce_requests.created_at >= ?", 6.months.ago.beginning_of_month)
                                        .group_by_month('produce_requests.created_at', last: 6, format: "%b %Y")
                                        .sum('produce_requests.quantity * produce_requests.price_offered')

        {
          user_role: 'farmer',
          profile: {
            id: profile.id,
            name: profile.name,
            location: profile.location,
            farm_size: profile.farm_size
          },
          statistics: {
            total_listings: total_listings,
            active_requests: active_requests,
            total_earnings: total_earnings.to_f
          },
          recent_listings: recent_listings.map { |listing| serialize_listing(listing) },
          charts: {
            produce_summary: produce_summary.map { |type, quantity| { produce_type: type, quantity: quantity } },
            monthly_earnings: monthly_earnings.map { |date, amount| { month: date, earnings: amount.to_f } }
          },
          unread_notifications: current_user.notifications.unread.count
        }
      end

      def trucker_dashboard
        profile = current_user.trucking_company
        
        return { error: 'Trucking company profile not found' } unless profile

        available_shipments = Shipment.available_for_bidding
                                     .includes(:produce_listing, :produce_request)
                                     .limit(10)
        
        active_bids = profile.shipment_bids.pending.count
        completed_shipments = profile.shipments.where(status: :delivered).count
        active_shipments = profile.shipments.active.includes(:produce_listing, :produce_request)

        {
          user_role: 'trucker',
          profile: {
            id: profile.id,
            company_name: profile.company_name,
            contact_person: profile.contact_person,
            fleet_size: profile.fleet_size
          },
          statistics: {
            active_bids: active_bids,
            completed_shipments: completed_shipments,
            active_shipments_count: active_shipments.count
          },
          available_shipments: available_shipments.map { |shipment| serialize_shipment(shipment) },
          active_shipments: active_shipments.map { |shipment| serialize_shipment(shipment) },
          unread_notifications: current_user.notifications.unread.count
        }
      end

      def market_dashboard
        profile = current_user.market_profile
        
        return { error: 'Market profile not found' } unless profile

        matching_service = ProduceMatchingService.new(profile)
        recommended_listings = matching_service.find_matches.limit(8)
        
        active_requests = profile.produce_requests.active.count
        recent_requests = profile.produce_requests.recent.includes(:produce_listing).limit(5)

        {
          user_role: 'market',
          profile: {
            id: profile.id,
            market_name: profile.market_name,
            location: profile.location,
            market_type: profile.market_type
          },
          statistics: {
            active_requests: active_requests,
            total_requests: profile.produce_requests.count
          },
          recommended_listings: recommended_listings.map { |listing| serialize_listing(listing) },
          recent_requests: recent_requests.map { |request| serialize_request(request) },
          unread_notifications: current_user.notifications.unread.count
        }
      end

      # Serializer helper methods
      def serialize_listing(listing)
        {
          id: listing.id,
          produce_type: listing.produce_type,
          quantity: listing.quantity,
          unit: listing.unit,
          price_per_unit: listing.price_per_unit,
          available_from: listing.available_from,
          available_until: listing.available_until,
          status: listing.status,
          farmer: {
            id: listing.farmer_profile.id,
            name: listing.farmer_profile.name,
            location: listing.farmer_profile.location
          }
        }
      end

      def serialize_shipment(shipment)
        {
          id: shipment.id,
          status: shipment.status,
          pickup_location: shipment.pickup_location,
          delivery_location: shipment.delivery_location,
          pickup_date: shipment.pickup_date,
          delivery_date: shipment.delivery_date,
          produce_listing: shipment.produce_listing ? {
            id: shipment.produce_listing.id,
            produce_type: shipment.produce_listing.produce_type,
            quantity: shipment.produce_listing.quantity
          } : nil,
          produce_request: shipment.produce_request ? {
            id: shipment.produce_request.id,
            quantity: shipment.produce_request.quantity
          } : nil
        }
      end

      def serialize_request(request)
        {
          id: request.id,
          quantity: request.quantity,
          price_offered: request.price_offered,
          status: request.status,
          delivery_date: request.delivery_date,
          produce_listing: request.produce_listing ? {
            id: request.produce_listing.id,
            produce_type: request.produce_listing.produce_type,
            farmer_name: request.produce_listing.farmer_profile.name
          } : nil
        }
      end
    end
  end
end