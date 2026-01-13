module Api
    module V1
        class Api::V1::ProfilesController < BaseController
            skip_before_action :check_profile_completion
    
            # GET /api/v1/profile/status
            def status
            render json: {
                success: true,
                data: {
                profile_complete: current_user.profile_complete?,
                user_role: current_user.user_role,
                profile_fields: required_profile_fields
                }
            }
            end
    
            # PATCH /api/v1/profile/complete
            def complete
            profile = find_or_create_profile
            
            if profile.update(profile_params)
                render json: {
                success: true,
                message: 'Profile completed successfully',
                data: serialize_profile(profile)
                }
            else
                render_error('Profile update failed', errors: profile.errors.full_messages)
            end
            end
    
            private
    
            def find_or_create_profile
            case current_user.user_role
            when 'farmer'
                current_user.farmer_profile || current_user.build_farmer_profile
            when 'trucker'
                current_user.trucking_company || current_user.build_trucking_company
            when 'market'
                current_user.market_profile || current_user.build_market_profile
            end
            end
    
            def profile_params
            case current_user.user_role
            when 'farmer'
                params.require(:profile).permit(:farm_name, :location, :farm_size, :farm_type, :description)
            when 'trucker'
                params.require(:profile).permit(:company_name, :license_number, :vehicle_type, :capacity, :service_areas, :description)
            when 'market'
                params.require(:profile).permit(:market_name, :location, :market_type, :operating_hours, :description)
            end
            end
    
            def required_profile_fields
            case current_user.user_role
            when 'farmer'
                ['farm_name', 'location', 'farm_size', 'farm_type']
            when 'trucker'
                ['company_name', 'license_number', 'vehicle_type', 'capacity']
            when 'market'
                ['market_name', 'location', 'market_type']
            end
            end
    
            def serialize_profile(profile)
            case current_user.user_role
            when 'farmer'
                FarmerProfileSerializer.new(profile).as_json
            when 'trucker'
                TruckingCompanySerializer.new(profile).as_json
            when 'market'
                MarketProfileSerializer.new(profile).as_json
            end
            end
        end
    end
end
  