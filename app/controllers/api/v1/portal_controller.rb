module Api
  module V1
    class PortalController < ApplicationController
      before_action :authenticate_user!

      def index
        render json: send("#{current_user.user_role}_portal")
      end

      private

      # Returns what the current user should see in their portal
      def farmer_portal
        {
          truckers: User.truckers.includes(:trucking_company).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              trucking_company: u.trucking_company&.slice(:company_name, :vehicle_types)
            )
          end,
          markets: User.markets.includes(:market_profile).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              market_profile: u.market_profile&.slice(:market_name, :market_type, :location)
            )
          end
        }
      end

      def trucker_portal
        {
          farmers: User.farmers.includes(:farmer_profile).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              farmer_profile: u.farmer_profile&.slice(:full_name, :farm_name, :farm_location)
            )
          end,
          markets: User.markets.includes(:market_profile).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              market_profile: u.market_profile&.slice(:market_name, :market_type, :location)
            )
          end
        }
      end

      def market_portal
        {
          farmers: User.farmers.includes(:farmer_profile).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              farmer_profile: u.farmer_profile&.slice(:full_name, :farm_name, :farm_location)
            )
          end,
          truckers: User.truckers.includes(:trucking_company).map do |u|
            u.as_json(only: [:id, :email, :phone_number]).merge(
              trucking_company: u.trucking_company&.slice(:company_name, :vehicle_types)
            )
          end
        }
      end
    end
  end
end
