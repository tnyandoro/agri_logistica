
module Api
  module V1
    class Api::V1::FarmerProfilesController < BaseController
      def show
      end

      def edit
      end

      def update
      end

      def farmer_profile_params
        params.require(:farmer_profile).permit(
          :business_name,
          :full_name,
          :farm_name,
          :farm_location,
          :production_capacity,
          :latitude,
          :longitude,
          produce_types: [],
          livestock: [],
          crops: [],
          certifications: []
        )
      end
    end
  end
end
