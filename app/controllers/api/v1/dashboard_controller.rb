# frozen_string_literal: true
module Api
  module V1
    class DashboardController < Api::V1::BaseController
      before_action :ensure_profile_present!

      def index
        render json: dashboard_payload
      rescue StandardError => e
        Rails.logger.error <<~LOG
          Dashboard Error:
          #{e.message}
          #{e.backtrace.first(10).join("\n")}
        LOG

        render json: dashboard_payload.merge(
          error: 'Failed to load dashboard data',
          message: e.message
        ), status: :internal_server_error
      end

      private

      # -----------------------------------
      # Main Payload
      # -----------------------------------
      def dashboard_payload
        {
          user_role: current_user.user_role,
          identity: identity_data,
          meta: meta_data,
          profile: profile_data,
          statistics: build_statistics,
          recent_listings: recent_listings_data,
          charts: build_charts
        }
      end

      # -----------------------------------
      # Guards
      # -----------------------------------
      def ensure_profile_present!
        return if current_user&.profile.present?

        render json: {
          error: 'Profile incomplete',
          redirect_to: '/profile/complete'
        }, status: :unprocessable_entity
      end

      # -----------------------------------
      # Identity (Header Info)
      # -----------------------------------
      def identity_data
        profile = current_user.profile

        {
          person_name: profile.try(:full_name) || current_user.email,
          company_name: extract_company_name(profile),
          avatar_url: avatar_url_for(current_user)
        }
      end

      def extract_company_name(profile)
        return nil unless profile

        case current_user.user_role
        when 'farmer'  then profile.farm_name || profile.business_name
        when 'trucker' then profile.company_name
        when 'market'  then profile.market_name
        else nil
        end
      end

      def avatar_url_for(user)
        # If you use ActiveStorage:
        if user.respond_to?(:avatar) && user.avatar.attached?
          Rails.application.routes.url_helpers.rails_blob_url(
            user.avatar,
            only_path: false
          )
        else
          nil
        end
      end

      # -----------------------------------
      # Meta (Time / Date)
      # -----------------------------------
      def meta_data
        {
          server_time: Time.current.strftime('%Y-%m-%d %H:%M'),
          timezone: Time.zone.name
        }
      end

      # -----------------------------------
      # Profile
      # -----------------------------------
      def profile_data
        profile = current_user.profile
        return {} unless profile

        base = { id: profile.id }

        case current_user.user_role
        when 'farmer'
          base.merge(
            business_name: profile.business_name,
            full_name: profile.full_name,
            farm_name: profile.farm_name,
            location: profile.location,
            produce_types: profile.produce_types,
            production_capacity: profile.production_capacity
          )
        when 'trucker'
          base.merge(
            company_name: profile.company_name,
            vehicle_types: profile.vehicle_types,
            capacity: profile.capacity,
            location: profile.location
          )
        when 'market'
          base.merge(
            market_name: profile.market_name,
            location: profile.location,
            description: profile.description
          )
        else
          base
        end.compact
      end

      # -----------------------------------
      # Statistics
      # -----------------------------------
      def build_statistics
        case current_user.user_role
        when 'farmer'  then farmer_stats
        when 'trucker' then trucker_stats
        when 'market'  then market_stats
        else {}
        end
      end

      def farmer_stats
        farmer = current_user.farmer_profile
        return empty_farmer_stats unless farmer

        listings = farmer.produce_listings

        {
          total_listings: listings.count,
          active_listings: listings.where(status: 'active').count,
          total_revenue: calculate_farmer_revenue(farmer),
          production_capacity: farmer.production_capacity.to_i,
          produce_types: farmer.produce_types&.size.to_i
        }
      end

      def empty_farmer_stats
        {
          total_listings: 0,
          active_listings: 0,
          total_revenue: 0,
          production_capacity: 0,
          produce_types: 0
        }
      end

      def trucker_stats
        company = current_user.trucking_company
        return { total_deliveries: 0, active_deliveries: 0 } unless company

        deliveries = company.deliveries

        {
          total_deliveries: deliveries.count,
          active_deliveries: deliveries.where(status: 'active').count,
          completed_deliveries: deliveries.where(status: 'completed').count,
          fleet_size: company.fleet_size.to_i
        }
      end

      def market_stats
        {
          total_listings: ProduceListing.count,
          total_requests: ProduceRequest.count,
          active_farmers: User.where(user_role: 'farmer').count,
          active_truckers: User.where(user_role: 'trucker').count,
          recent_activity: User.where('last_sign_in_at > ?', 7.days.ago).count
        }
      end

      # -----------------------------------
      # Revenue
      # -----------------------------------
      def calculate_farmer_revenue(farmer)
        ProduceRequest
          .joins(:produce_listing)
          .where(produce_listings: { farmer_profile_id: farmer.id })
          .where(status: 'completed')
          .sum('produce_requests.quantity * produce_requests.price_offered')
      end

      # -----------------------------------
      # Recent listings
      # -----------------------------------
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
            title: listing.title || listing.produce_type || "Listing ##{listing.id}",
            price: listing.price_per_unit,
            quantity: listing.quantity_available,
            unit: listing.unit,
            status: listing.status,
            created_at: listing.created_at.strftime('%Y-%m-%d %H:%M')
          }
        end
      end

      # -----------------------------------
      # Charts
      # -----------------------------------
      def build_charts
        case current_user.user_role
        when 'farmer'
          farmer_charts
        when 'market'
          market_charts
        else
          {}
        end
      end

      def farmer_charts
        farmer = current_user.farmer_profile
        return {} unless farmer

        {
          monthly_earnings: farmer.respond_to?(:monthly_earnings) ? farmer.monthly_earnings : []
        }
      end

      def market_charts
        {}
      end
    end
  end
end
