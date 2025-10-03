# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  # IMPORTANT: Skip the ApplicationController's authenticate_user! callback
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :check_profile_completion
  
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
        :contact_person,
        :description,
        :purchase_volume,
        :delivery_preferences,
        :organic_certified,
        :gap_certified,
        :haccp_certified,
        :demand_volume, 
        :payment_terms, 
        :operating_hours, 
        :additional_requirements,
        location: [:address, :lat, :lng],
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
    
    # Convert farm_location string to hash format
    if profile_params[:farm_location].present?
      # If it's already a string (from the form), convert to hash
      if profile_params[:farm_location].is_a?(String)
        profile_params[:farm_location] = {
          'address' => profile_params[:farm_location]
        }
      elsif profile_params[:farm_location].is_a?(Hash)
        # If it's already a hash, ensure it has the right format
        profile_params[:farm_location] = {
          'address' => profile_params[:farm_location][:address] || profile_params[:farm_location]['address'],
          'lat' => profile_params[:farm_location][:lat] || profile_params[:farm_location]['lat'],
          'lng' => profile_params[:farm_location][:lng] || profile_params[:farm_location]['lng']
        }.compact
      end
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
    if params.dig(:trucking_company_attributes, :routes).present?
      routes_params = params[:trucking_company_attributes][:routes]
      company_params[:routes] = process_routes(routes_params)
    else
      company_params[:routes] = []
    end
    
    # Process rates from form
    if params.dig(:trucking_company_attributes, :rates).present?
      rates_params = params[:trucking_company_attributes][:rates]
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
    
    # Process location - it comes as a nested hash from fields_for
    if profile_params[:location].present?
      location_data = profile_params[:location]
      
      # Handle both ActionController::Parameters and Hash
      if location_data.is_a?(ActionController::Parameters) || location_data.is_a?(Hash)
        # Extract address from the location hash
        address = location_data[:address] || location_data['address']
        
        if address.present?
          # Store as a hash with address
          profile_params[:location] = {
            'address' => address.to_s.strip
          }
        else
          # If no address, set to nil to avoid validation errors
          profile_params[:location] = nil
        end
      elsif location_data.is_a?(String)
        # If somehow it comes as a string, wrap it
        profile_params[:location] = {
          'address' => location_data.strip
        }
      end
    end
    
    # Ensure preferred_produces is an array and remove blanks
    if profile_params[:preferred_produces].present?
      profile_params[:preferred_produces] = Array(profile_params[:preferred_produces]).reject(&:blank?)
    else
      profile_params[:preferred_produces] = []
    end
    
    # Handle boolean checkboxes - ensure they're proper booleans
    [:organic_certified, :gap_certified, :haccp_certified].each do |field|
      if profile_params.key?(field)
        profile_params[field] = ActiveRecord::Type::Boolean.new.cast(profile_params[field])
      end
    end
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