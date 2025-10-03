class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, raise: false
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def new
    @user_role = params[:user_role] || 'farmer'
    
    build_resource({})
    resource.user_role = @user_role
    
    # Build the appropriate nested profile
    case @user_role
    when 'farmer'
      resource.build_farmer_profile
      render 'users/registrations/new_farmer'
    when 'trucker'
      resource.build_trucking_company
      render 'users/registrations/new_trucker'
    when 'market'
      resource.build_market_profile
      render 'users/registrations/new_market'
    else
      render 'devise/registrations/new'
    end
  end

  def create
    build_resource(sign_up_params)
    
    # Manually set the user_role from params
    resource.user_role = params[:user][:user_role] if params[:user][:user_role].present?

    # Save user with nested attributes
    if resource.save
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      
      # Store the user_role for re-rendering
      @user_role = resource.user_role || params[:user][:user_role] || 'farmer'
      
      # Re-render the appropriate template
      case @user_role
      when 'farmer'
        render 'users/registrations/new_farmer', status: :unprocessable_entity
      when 'trucker'
        render 'users/registrations/new_trucker', status: :unprocessable_entity
      when 'market'
        render 'users/registrations/new_market', status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :phone_number, 
      :user_role,
      farmer_profile_attributes: [
        :full_name, 
        :farm_name, 
        :production_capacity,
        :farm_location,
        produce_types: [], 
        crops: [], 
        livestock: [], 
        certifications: []
      ],
      trucking_company_attributes: [
        :company_name, 
        :fleet_size, 
        :insurance_details, 
        :contact_person,
        :registration_numbers,
        :routes,
        :rates,
        vehicle_types: []
      ],
      market_profile_attributes: [
        :market_name, 
        :market_type, 
        :demand_volume, 
        :payment_terms, 
        :operating_hours, 
        :additional_requirements,
        :location,
        preferred_produces: []
      ]
    ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number])
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  def sign_up_params
    permitted_params = devise_parameter_sanitizer.sanitize(:sign_up)
    
    # Process nested attributes before saving
    process_nested_attributes(permitted_params) if permitted_params.present?
    
    permitted_params
  end

  private

  def process_nested_attributes(params)
    user_role = params[:user_role]
    
    case user_role
    when 'farmer'
      process_farmer_profile(params)
    when 'trucker'
      process_trucking_company(params)
    when 'market'
      process_market_profile(params)
    end
  end

  def process_farmer_profile(params)
    return unless params[:farmer_profile_attributes].present?
    
    profile_params = params[:farmer_profile_attributes]
    
    # Convert farm_location hash from nested params
    if params.dig(:user, :farmer_profile_attributes, :farm_location).present?
      location_params = params[:user][:farmer_profile_attributes][:farm_location]
      profile_params[:farm_location] = {
        'address' => location_params[:address],
        'lat' => location_params[:lat],
        'lng' => location_params[:lng]
      }.compact
    end
    
    # Ensure arrays are properly formatted
    profile_params[:produce_types] = Array(profile_params[:produce_types]).reject(&:blank?)
    profile_params[:crops] = Array(profile_params[:crops]).reject(&:blank?)
    profile_params[:livestock] = Array(profile_params[:livestock]).reject(&:blank?)
    profile_params[:certifications] = Array(profile_params[:certifications]).reject(&:blank?)
  end

  def process_trucking_company(params)
    return unless params[:trucking_company_attributes].present?
    
    company_params = params[:trucking_company_attributes]
    
    # Convert registration_numbers from textarea to array
    if company_params[:registration_numbers].is_a?(String)
      company_params[:registration_numbers] = company_params[:registration_numbers]
        .split("\n")
        .map(&:strip)
        .reject(&:blank?)
    end
    
    # Process routes from form
    if params.dig(:user, :trucking_company_attributes, :routes).present?
      routes_params = params[:user][:trucking_company_attributes][:routes]
      company_params[:routes] = process_routes(routes_params)
    else
      company_params[:routes] = []
    end
    
    # Process rates from form
    if params.dig(:user, :trucking_company_attributes, :rates).present?
      rates_params = params[:user][:trucking_company_attributes][:rates]
      company_params[:rates] = process_rates(rates_params)
    else
      company_params[:rates] = []
    end
    
    # Ensure vehicle_types is an array
    company_params[:vehicle_types] = Array(company_params[:vehicle_types]).reject(&:blank?)
  end

  def process_market_profile(params)
    return unless params[:market_profile_attributes].present?
    
    profile_params = params[:market_profile_attributes]
    
    # Convert location hash from nested params
    if params.dig(:user, :market_profile_attributes, :location).present?
      location_params = params[:user][:market_profile_attributes][:location]
      profile_params[:location] = {
        'address' => location_params[:address],
        'lat' => location_params[:lat],
        'lng' => location_params[:lng]
      }.compact
    end
    
    # Ensure preferred_produces is an array
    profile_params[:preferred_produces] = Array(profile_params[:preferred_produces]).reject(&:blank?)
  end

  def process_routes(routes_params)
    return [] unless routes_params.is_a?(Array)
    
    routes_params.map do |route|
      next if route.values.all?(&:blank?)
      
      {
        'from' => route[:from]&.strip,
        'to' => route[:to]&.strip,
        'distance' => route[:distance]&.to_i
      }.compact
    end.compact
  end

  def process_rates(rates_params)
    return [] unless rates_params.is_a?(Array)
    
    rates_params.map do |rate|
      next if rate.values.all?(&:blank?)
      
      {
        'type' => rate[:type],
        'rate' => rate[:rate]&.to_f,
        'currency' => rate[:currency] || 'ZAR'
      }.compact
    end.compact
  end
end