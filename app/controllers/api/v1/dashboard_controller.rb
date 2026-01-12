# app/controllers/api/v1/dashboard_controller.rb
module Api
  module V1
    class Api::V1::DashboardController < Api::V1::BaseController
      def index
        render json: {
          user_role: current_user.user_role,
          profile: profile_data,
          statistics: build_statistics,
          recent_listings: recent_listings_data,
          charts: build_charts
        }
      rescue StandardError => e
        Rails.logger.error "Dashboard Error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { 
          error: 'Failed to load dashboard data',
          message: e.message,
          user_role: current_user.user_role,
          statistics: {},
          recent_listings: []
        }, status: :internal_server_error
      end
      
      private
      
      def profile_data
        # Use the User model's built-in profile method
        profile = current_user.profile
        
        return nil unless profile
        
        # Build profile data based on the profile type
        data = { id: profile.id }
        
        case current_user.user_role
        when 'farmer'
          data.merge!(
            business_name: profile.business_name,
            full_name: profile.full_name,
            farm_name: profile.farm_name,
            location: profile.location,
            produce_types: profile.produce_types,
            production_capacity: profile.production_capacity
          )
        when 'trucker'
          data.merge!(
            company_name: profile.company_name,
            vehicle_types: profile.vehicle_types,
            capacity: profile.capacity,
            location: profile.location
          )
        when 'market'
          data.merge!(
            market_name: profile.market_name,
            location: profile.location,
            description: profile.description
          )
        end
        
        data.compact
      end
      
      def build_statistics
        case current_user.user_role
        when 'farmer'
          build_farmer_stats
        when 'trucker'
          build_trucker_stats
        when 'market'
          build_market_stats
        else
          {}
        end
      end
      
      def build_farmer_stats
        farmer_profile = current_user.farmer_profile
        return { total_listings: 0, active_listings: 0, total_revenue: 0 } unless farmer_profile
        
        # Use produce_listings from FarmerProfile
        listings = farmer_profile.produce_listings
        
        {
          total_listings: listings.count,
          active_listings: listings.where(status: 'active').count,
          total_revenue: calculate_farmer_revenue(farmer_profile),
          production_capacity: farmer_profile.production_capacity || 0,
          produce_types: farmer_profile.produce_types.size
        }
      rescue StandardError => e
        Rails.logger.error "Error building farmer stats: #{e.message}"
        { total_listings: 0, active_listings: 0, total_revenue: 0 }
      end
      
      def build_buyer_stats
        # If you have a buyer/purchaser role in the future
        {
          total_orders: 0,
          pending_orders: 0,
          completed_orders: 0
        }
      end
      
      def build_trucker_stats
        trucking_company = current_user.trucking_company
        return { total_deliveries: 0, active_deliveries: 0, completed_deliveries: 0 } unless trucking_company
        
        # Adjust based on your delivery/transport model
        deliveries = trucking_company.try(:deliveries) || []
        
        {
          total_deliveries: deliveries.count,
          active_deliveries: deliveries.where(status: 'active').count,
          completed_deliveries: deliveries.where(status: 'completed').count,
          fleet_size: trucking_company.fleet_size || 0
        }
      rescue StandardError => e
        Rails.logger.error "Error building trucker stats: #{e.message}"
        { total_deliveries: 0, active_deliveries: 0, completed_deliveries: 0 }
      end
      
      def build_market_stats
        market_profile = current_user.market_profile
        return { total_orders: 0, total_suppliers: 0 } unless market_profile
        
        # Adjust based on your market's associations
        {
          total_listings: ProduceListing.count,
          total_requests: ProduceRequest.count,
          active_farmers: User.user_role_farmer.count,
          active_truckers: User.user_role_trucker.count,
          recent_activity: User.where('last_sign_in_at > ?', 7.days.ago).count
        }
      rescue StandardError => e
        Rails.logger.error "Error building market stats: #{e.message}"
        { total_listings: 0, total_requests: 0, active_farmers: 0 }
      end
      
      def calculate_farmer_revenue(farmer_profile)
        # Calculate from completed produce requests
        ProduceRequest.joins(:produce_listing)
                      .where(produce_listings: { farmer_profile_id: farmer_profile.id })
                      .where(status: 'completed')
                      .sum('produce_requests.quantity * produce_requests.price_offered')
      rescue StandardError => e
        Rails.logger.error "Error calculating revenue: #{e.message}"
        0
      end
      
      def recent_listings_data
        return [] unless current_user.user_role == 'farmer'
        
        farmer_profile = current_user.farmer_profile
        return [] unless farmer_profile
        
        farmer_profile.produce_listings
                      .order(created_at: :desc)
                      .limit(5)
                      .map do |listing|
          {
            id: listing.id,
            title: listing.try(:title) || listing.try(:produce_type) || "Listing ##{listing.id}",
            price: listing.try(:price_per_unit),
            quantity: listing.try(:quantity_available),
            unit: listing.try(:unit),
            status: listing.try(:status),
            created_at: listing.created_at.strftime("%Y-%m-%d %H:%M")
          }
        end
      rescue StandardError => e
        Rails.logger.error "Error fetching recent listings: #{e.message}"
        []
      end
      
      def build_charts
        case current_user.user_role
        when 'farmer'
          build_farmer_charts
        when 'trucker'
          build_trucker_charts
        when 'market'
          build_market_charts
        else
          {}
        end
      rescue StandardError => e
        Rails.logger.error "Error building charts: #{e.message}"
        {}
      end
      
      def build_farmer_charts
        farmer_profile = current_user.farmer_profile
        return {} unless farmer_profile
        
        {
          monthly_earnings: farmer_profile.monthly_earnings
        }
      rescue StandardError => e
        Rails.logger.error "Error building farmer charts: #{e.message}"
        {}
      end
      
      def build_trucker_charts
        # Add trucker-specific charts if needed
        {}
      end
      
      def build_market_charts
        # Add market-specific charts if needed
        {}
      end
    end
  end
end