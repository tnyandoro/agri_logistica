module Api
  module V1
    class DashboardController < Api::V1::BaseController
      def index
        profile = current_user.profile

        unless profile
          return render json: {
            error: 'Profile incomplete',
            redirect_to: complete_profile_path
          }, status: :unprocessable_entity
        end

        render json: {
          user_role: current_user.user_role,
          profile: profile_data(profile),
          statistics: build_statistics,
          recent_listings: recent_listings_data,
          charts: build_charts
        }
      rescue StandardError => e
        Rails.logger.error "Dashboard Error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: {
          error: 'Failed to load dashboard data',
          message: e.message
        }, status: :internal_server_error
      end

      private

      # ---------------------------------------------------
      # PROFILE DATA
      # ---------------------------------------------------
      def profile_data(profile)
        data = { id: profile.id }

        case current_user.user_role
        when 'farmer'
          data.merge!(
            business_name: profile.business_name,
            full_name: profile.full_name,
            farm_name: profile.farm_name,
            farm_location: profile.farm_location,
            produce_types: profile.produce_types,
            production_capacity: profile.production_capacity
          )
        when 'trucker'
          data.merge!(
            business_name: profile.business_name,
            company_name: profile.company_name,
            vehicle_types: profile.vehicle_types,
            fleet_size: profile.fleet_size
          )
        when 'market'
          data.merge!(
            business_name: profile.business_name,
            market_name: profile.market_name,
            description: profile.description,
            location: profile.location
          )
        end

        data.compact
      end

      # ---------------------------------------------------
      # STATISTICS
      # ---------------------------------------------------
      def build_statistics
        case current_user.user_role
        when 'farmer'  then build_farmer_stats
        when 'trucker' then build_trucker_stats
        when 'market'  then build_market_stats
        else {}
        end
      end

      def build_farmer_stats
        farmer = current_user.farmer_profile
        return empty_farmer_stats unless farmer

        listings = farmer.produce_listings

        {
          total_listings: listings.count,
          active_listings: listings.where(status: 0).count, # enum :active
          total_revenue: calculate_farmer_revenue(farmer),
          produce_types: farmer.produce_types.size
        }
      end

      def build_trucker_stats
        company = current_user.trucking_company
        return empty_trucker_stats unless company

        shipments = company.shipments

        {
          total_shipments: shipments.count,
          active_shipments: shipments.where(status: [0, 1]).count,
          completed_shipments: shipments.where(status: 2).count,
          fleet_size: company.fleet_size || 0
        }
      end

      def build_market_stats
        {
          total_farmers: FarmerProfile.count,
          total_truckers: TruckingCompany.count,
          total_listings: ProduceListing.count,
          total_requests: ProduceRequest.count
        }
      end

      # ---------------------------------------------------
      # FARMER REVENUE
      # ---------------------------------------------------
      def calculate_farmer_revenue(farmer)
        ProduceRequest
          .joins(:produce_listing)
          .where(produce_listings: { farmer_profile_id: farmer.id })
          .where(status: 2) # completed
          .sum('produce_requests.quantity * COALESCE(produce_requests.price_offered, 0)')
      end

      # ---------------------------------------------------
      # RECENT LISTINGS
      # ---------------------------------------------------
      def recent_listings_data
        return [] unless current_user.user_role == 'farmer'

        farmer = current_user.farmer_profile
        return [] unless farmer

        farmer.produce_listings
              .order(created_at: :desc)
              .limit(5)
              .map do |listing|
          {
            id: listing.id,
            title: listing.title,
            produce_type: listing.produce_type,
            price_per_unit: listing.price_per_unit,
            quantity: listing.quantity,
            unit: listing.unit,
            status: listing.status,
            created_at: listing.created_at.strftime('%Y-%m-%d %H:%M')
          }
        end
      end

      # ---------------------------------------------------
      # CHARTS (SAFE PLACEHOLDERS)
      # ---------------------------------------------------
      def build_charts
        case current_user.user_role
        when 'farmer'  then build_farmer_charts
        when 'trucker' then {}
        when 'market'  then {}
        else {}
        end
      end

      def build_farmer_charts
        farmer = current_user.farmer_profile
        return {} unless farmer

        {
          listings_per_month: farmer.produce_listings
                                     .group_by_month(:created_at)
                                     .count
        }
      end

      # ---------------------------------------------------
      # EMPTY FALLBACKS
      # ---------------------------------------------------
      def empty_farmer_stats
        { total_listings: 0, active_listings: 0, total_revenue: 0, produce_types: 0 }
      end

      def empty_trucker_stats
        { total_shipments: 0, active_shipments: 0, completed_shipments: 0, fleet_size: 0 }
      end
    end
  end
end
