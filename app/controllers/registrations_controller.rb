# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  skip_before_action :require_no_authentication, only: [:complete_profile, :update_profile]

  def new
    super do |user|
      if params[:user_role].present? && params[:user_role].in?(%w[farmer trucker market])
        user.user_role = params[:user_role]
      end
    end
  end

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    
    if resource.persisted?
      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        respond_with resource, location: complete_profile_path
      else
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def complete_profile
    @user = current_user
    @profile = @user.profile
    
    unless @profile
      flash[:alert] = 'Profile could not be initialized. Please contact support.'
      redirect_to root_path
      return
    end

    # Check if profile is already completed
    if profile_completed?(@profile)
      redirect_to dashboard_path, notice: 'Your profile is already complete!'
    end
  end

  def update_profile
    @user = current_user
    @profile = @user.profile

    unless @profile
      redirect_to root_path, alert: 'Profile not found.'
      return
    end

    if @profile.update(profile_params)
      # Update geocoding if location was provided
      geocode_profile(@profile) if should_geocode?
      
      redirect_to dashboard_path, notice: 'Profile completed successfully!'
    else
      flash.now[:alert] = 'Please fix the errors below.'
      render :complete_profile, status: :unprocessable_entity
    end
  end

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :user_role])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone])
  end

  def profile_params
    case current_user.user_role
    when 'farmer'
      farmer_profile_params
    when 'trucker'
      trucking_company_params
    when 'market'
      market_profile_params
    else
      {}
    end
  end

  def farmer_profile_params
    params.require(:farmer_profile).permit(
      :full_name, :farm_name, :production_capacity,
      produce_types: [], 
      crops: [], 
      livestock: [], 
      certifications: []
    ).tap do |permitted|
      if params[:farmer_profile][:farm_location].present?
        location = params[:farmer_profile][:farm_location]
        permitted[:farm_location] = {
          address: location[:address],
          lat: location[:lat],
          lng: location[:lng]
        }.compact
      end
    end
  end

  def trucking_company_params
    params.require(:trucking_company).permit(
      :company_name, :fleet_size, :insurance_details, :contact_person,
      vehicle_types: [], 
      registration_numbers: []
    ).tap do |permitted|
      if params[:trucking_company][:routes].present?
        permitted[:routes] = params[:trucking_company][:routes].map do |route|
          route.permit(:from, :to, :distance).to_h.symbolize_keys
        end
      end
      
      if params[:trucking_company][:rates].present?
        permitted[:rates] = params[:trucking_company][:rates].map do |rate|
          rate.permit(:type, :rate, :currency).to_h.symbolize_keys
        end
      end
    end
  end

  def market_profile_params
    params.require(:market_profile).permit(
      :market_name, :market_type, :demand_volume, :payment_terms, :operating_hours,
      preferred_produces: []
    ).tap do |permitted|
      if params[:market_profile][:location].present?
        location = params[:market_profile][:location]
        permitted[:location] = {
          address: location[:address],
          lat: location[:lat],
          lng: location[:lng]
        }.compact
      end
    end
  end

  def profile_completed?(profile)
    case current_user.user_role
    when 'farmer'
      profile.full_name.present? && profile.farm_name.present?
    when 'trucker'
      profile.company_name.present?
    when 'market'
      profile.market_name.present?
    else
      false
    end
  end

  def should_geocode?
    case current_user.user_role
    when 'farmer'
      profile_params.dig(:farm_location, :address).present?
    when 'market'
      profile_params.dig(:location, :address).present?
    else
      false
    end
  end

  def geocode_profile(profile)
    # Extract address from the appropriate location field
    address = case current_user.user_role
    when 'farmer'
      profile.farm_location&.dig('address')
    when 'market'
      profile.location&.dig('address')
    end

    return unless address.present?

    # Use Geocoder or your preferred geocoding service
    # Example with Geocoder gem:
    coordinates = Geocoder.coordinates(address)
    if coordinates
      profile.update_columns(latitude: coordinates[0], longitude: coordinates[1])
    end
  rescue StandardError => e
    Rails.logger.error "Geocoding failed: #{e.message}"
    # Don't fail the whole operation if geocoding fails
  end
end