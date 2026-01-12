module Api
  module V1    
    class Api::V1::TruckingCompaniesController < BaseController
      def show
      end

      def edit
      end

      def update
      end

      def trucking_company_params
        params.require(:trucking_company).permit(
          :business_name,
          :company_name,
          :contact_person,
          :fleet_size,
          :insurance_details,
          vehicle_types: [],
          registration_numbers: [],
          routes: [],
          rates: []
        )
      end
    end
  end
end
