class Users::RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]
  
    def new
      super
      @user.role = params[:role] if params[:role].in?(['farmer', 'trucker', 'market'])
    end
  
    def create
      super do |user|
        if user.persisted?
          redirect_to complete_profile_path and return
        end
      end
    end
  
    def complete_profile
      @user = current_user
      @profile = @user.profile
      
      unless @profile
        redirect_to root_path, alert: 'Profile not found. Please contact support.'
        return
      end
    end
  
    def update_profile
      @user = current_user
      @profile = @user.profile
  
      if @profile&.update(profile_params)
        redirect_to dashboard_path, notice: 'Profile completed successfully!'
      else
        flash.now[:alert] = 'Please fix the errors below.'
        render :complete_profile, status: :unprocessable_entity
      end
    end
  
    private
  
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :role])
    end
  
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:phone])
    end
  
    def profile_params
      case current_user.role
      when 'farmer'
        farmer_profile_params
      when 'trucker'
        trucking_company_params
      when 'market'
        market_profile_params
      end
    end
  
    def farmer_profile_params
      params.require(:farmer_profile).permit(
        :full_name, :farm_name, :production_capacity,
        produce_types: [], crops: [], livestock: [], certifications: [],
        farm_location: {}
      ).tap do |permitted|
        # Handle nested farm_location hash
        if params[:farmer_profile][:farm_location].present?
          permitted[:farm_location] = params[:farmer_profile][:farm_location].permit(:address, :lat, :lng).to_h
        end
      end
    end
  
    def trucking_company_params
      params.require(:trucking_company).permit(
        :company_name, :fleet_size, :insurance_details, :contact_person,
        vehicle_types: [], registration_numbers: []
      ).tap do |permitted|
        # Handle routes and rates arrays
        if params[:trucking_company][:routes].present?
          permitted[:routes] = params[:trucking_company][:routes].map do |route|
            route.permit(:from, :to, :distance).to_h
          end
        end
        
        if params[:trucking_company][:rates].present?
          permitted[:rates] = params[:trucking_company][:rates].map do |rate|
            rate.permit(:type, :rate, :currency).to_h
          end
        end
      end
    end
  
    def market_profile_params
      params.require(:market_profile).permit(
        :market_name, :market_type, :demand_volume, :payment_terms, :operating_hours,
        preferred_produces: []
      ).tap do |permitted|
        # Handle nested location hash
        if params[:market_profile][:location].present?
          permitted[:location] = params[:market_profile][:location].permit(:address, :lat, :lng).to_h
        end
      end
    end
  end