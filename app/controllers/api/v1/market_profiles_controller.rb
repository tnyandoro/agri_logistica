module Api
  module V1   
    class Api::V1::MarketProfilesController < BaseController
        def show
        end

        def edit
        end

        def update
        end

        def market_profile_params
          params.require(:market_profile).permit(
            :business_name,
            :market_name,
            :market_type,
            :location,
            :demand_volume,
            :payment_terms,
            :operating_hours,
            :contact_person,
            :description,
            :purchase_volume,
            :delivery_preferences,
            :organic_certified,
            :gap_certified,
            :haccp_certified,
            :additional_requirements,
            :latitude,
            :longitude,
            preferred_produces: []
          )
        end
    end
  end
end
