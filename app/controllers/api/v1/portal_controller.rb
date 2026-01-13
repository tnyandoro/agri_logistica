# app/controllers/api/v1/portal_controller.rb
module Api
  module V1
    class PortalController < BaseController
      skip_before_action :check_profile_completion, only: [:index]


      # GET /api/v1/portal
      def index
        render json: portal_data_for_role
      end

      private

      # Map user roles to portal methods
      ROLE_PORTAL_MAP = {
        'farmer'  => :farmer_portal_data,
        'trucker' => :trucker_portal_data,
        'market'  => :market_portal_data
      }.freeze

      def portal_data_for_role
        return {} unless current_user

        method = ROLE_PORTAL_MAP[current_user.user_role]
        method ? send(method) : {}
      rescue StandardError => e
        log_error(e, "Error generating portal data for role: #{current_user&.user_role}")
        {}
      end

      # ------------------------
      # Role-specific portal data
      # ------------------------
      def farmer_portal_data
        {
          markets:     safe_fetch(:fetch_markets),
          truckers:    safe_fetch(:fetch_truckers),
          my_listings: safe_fetch(:fetch_farmer_listings),
          requests:    safe_fetch(:fetch_farmer_requests)
        }
      end

      def trucker_portal_data
        {
          farmers:        safe_fetch(:fetch_farmers),
          markets:        safe_fetch(:fetch_markets),
          available_jobs: safe_fetch(:fetch_available_deliveries)
        }
      end

      def market_portal_data
        {
          farmers:        safe_fetch(:fetch_farmers),
          truckers:       safe_fetch(:fetch_truckers),
          all_listings:   safe_fetch(:fetch_all_listings),
          recent_requests:safe_fetch(:fetch_recent_requests)
        }
      end

      # ------------------------
      # Fetch methods
      # ------------------------
      def fetch_farmers
        User.user_role_farmer.includes(:farmer_profile).limit(20).filter_map do |user|
          profile = user.farmer_profile
          next unless profile

          {
            id: user.id,
            email: user.email,
            name: profile.name,
            farm_name: profile.farm_name,
            produce_types: profile.produce_types,
            location: profile.location
          }
        end
      end

      def fetch_truckers
        User.user_role_trucker.includes(:trucking_company).limit(20).filter_map do |user|
          company = user.trucking_company
          next unless company

          {
            id: user.id,
            email: user.email,
            company_name: company.company_name,
            vehicle_types: company.vehicle_types,
            fleet_size: company.fleet_size,
            contact_person: company.contact_person
          }
        end
      end

      def fetch_markets
        User.user_role_market.includes(:market_profile).limit(20).filter_map do |user|
          profile = user.market_profile
          next unless profile

          {
            id: user.id,
            email: user.email,
            market_name: profile.market_name,
            location: profile.location,
            description: profile.description
          }
        end
      end

      def fetch_farmer_listings
        farmer_profile = current_user.farmer_profile
        return [] unless farmer_profile

        farmer_profile.produce_listings
                       .order(created_at: :desc)
                       .limit(10)
                       .map do |listing|
          {
            id: listing.id,
            produce_type: listing.produce_type,
            quantity_available: listing.quantity_available,
            price_per_unit: listing.price_per_unit,
            unit: listing.unit,
            status: listing.status,
            created_at: listing.created_at.iso8601
          }
        end
      end

      def fetch_all_listings
        ProduceListing.includes(farmer_profile: :user)
                      .order(created_at: :desc)
                      .limit(20)
                      .map do |listing|
          {
            id: listing.id,
            produce_type: listing.produce_type,
            quantity_available: listing.quantity_available,
            price_per_unit: listing.price_per_unit,
            unit: listing.unit,
            status: listing.status,
            farmer_name: listing.farmer_profile&.name,
            created_at: listing.created_at.iso8601
          }
        end
      end

      def fetch_farmer_requests
        farmer_profile = current_user.farmer_profile
        return [] unless farmer_profile

        ProduceRequest.joins(:produce_listing)
                      .where(produce_listings: { farmer_profile_id: farmer_profile.id })
                      .order(created_at: :desc)
                      .limit(10)
                      .map do |request|
          {
            id: request.id,
            produce_listing_id: request.produce_listing_id,
            quantity: request.quantity,
            price_offered: request.price_offered,
            status: request.status,
            created_at: request.created_at.iso8601
          }
        end
      end

      def fetch_recent_requests
        ProduceRequest.includes(produce_listing: { farmer_profile: :user })
                      .order(created_at: :desc)
                      .limit(20)
                      .map do |request|
          {
            id: request.id,
            quantity: request.quantity,
            price_offered: request.price_offered,
            status: request.status,
            produce_type: request.produce_listing&.produce_type,
            farmer_name: request.produce_listing&.farmer_profile&.name,
            created_at: request.created_at.iso8601
          }
        end
      end

      def fetch_available_deliveries
        []
      end

      # ------------------------
      # Utilities
      # ------------------------
      def safe_fetch(method_name)
        send(method_name)
      rescue StandardError => e
        log_error(e, "Error in #{method_name}")
        []
      end

      def log_error(exception, context = nil)
        Rails.logger.error(
          "[PortalController] #{context}: #{exception.class} - #{exception.message}\n#{exception.backtrace.join("\n")}"
        )
      end
    end
  end
end
