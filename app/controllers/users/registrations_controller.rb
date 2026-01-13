# frozen_string_literal: true

require 'jwt'

module Users
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json
    
    # Skip ALL Devise callbacks and actions
    skip_before_action :verify_authenticity_token, if: :json_request?
    skip_before_action :authenticate_user!, raise: false
    skip_before_action :check_profile_completion
    skip_before_action :require_no_authentication, only: [:create]
    skip_before_action :configure_sign_up_params, only: [:create], raise: false
    
    before_action :configure_permitted_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]

    # POST /users - Completely override Devise's create
    def create
      user = User.new(user_params)
      user.user_role = params[:user][:user_role] if params[:user][:user_role].present?
      
      # Build the appropriate profile
      build_profile_for_user(user)
      
      if user.save
        token = generate_jwt_token(user)
        
        render json: {
          message: 'Signed up successfully.',
          token: token,
          token_type: 'Bearer',
          expires_in: 24.hours.to_i,
          user: user_data(user)
        }, status: :created
      else
        Rails.logger.error "Registration failed: #{user.errors.full_messages}"
        
        render json: {
          message: "User couldn't be created.",
          errors: user.errors.full_messages,
          validation_errors: format_validation_errors(user)
        }, status: :unprocessable_entity
      end
    end

    # PUT /users
    def update
      user = User.find(current_user.id)

      if user.update(account_update_params)
        render json: {
          message: 'Account updated successfully.',
          user: user_data(user)
        }, status: :ok
      else
        render json: {
          message: "Account couldn't be updated.",
          errors: user.errors.full_messages,
          validation_errors: format_validation_errors(user)
        }, status: :unprocessable_entity
      end
    end

    # DELETE /users
    def destroy
      user = User.find(current_user.id)
      user.destroy
      
      render json: {
        message: 'Account deleted successfully.'
      }, status: :ok
    end

    protected

    def configure_permitted_params
      # This method configures what parameters are allowed
    end

    def configure_account_update_params
      # For account updates
    end

    def user_params
      permitted = params.require(:user).permit(
        :email,
        :password,
        :password_confirmation,
        :phone_number,
        :user_role,
        farmer_profile_attributes: [
          :full_name,
          :farm_name,
          :production_capacity,
          { farm_location: [:address, :lat, :lng] },
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
          vehicle_types: [],
          registration_numbers: [],
          routes: [:from, :to, :distance],
          rates: [:type, :rate, :currency]
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
          { location: [:address, :lat, :lng] },
          preferred_produces: []
        ]
      )
      
      # Process nested attributes
      process_nested_attributes(permitted)
      
      permitted
    end

    def account_update_params
      params.require(:user).permit(:phone_number, :password, :password_confirmation, :current_password)
    end

    private

    # Build the appropriate profile based on user role
    def build_profile_for_user(user)
      return if user.user_role.blank?
      
      case user.user_role.to_sym
      when :farmer
        user.build_farmer_profile unless user.farmer_profile
      when :trucker
        user.build_trucking_company unless user.trucking_company
      when :market
        user.build_market_profile unless user.market_profile
      end
    end

    # Generate JWT token for the user
    def generate_jwt_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        user_role: user.user_role,
        exp: 24.hours.from_now.to_i,
        iat: Time.now.to_i
      }
      
      JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    end

    # Serialize user data for response
    def user_data(user)
      data = {
        id: user.id,
        email: user.email,
        phone_number: user.phone_number,
        user_role: user.user_role,
        profile_complete: user.profile_complete?,
        created_at: user.created_at,
        next_step: next_step_for(user)
      }

      # Add profile data if it exists
      case user.user_role.to_sym
      when :farmer
        data[:farmer_profile] = serialize_farmer_profile(user.farmer_profile) if user.farmer_profile
      when :trucker
        data[:trucking_company] = serialize_trucking_company(user.trucking_company) if user.trucking_company
      when :market
        data[:market_profile] = serialize_market_profile(user.market_profile) if user.market_profile
      end

      data
    end

    def serialize_farmer_profile(profile)
      {
        id: profile.id,
        full_name: profile.full_name,
        farm_name: profile.farm_name,
        production_capacity: profile.production_capacity,
        farm_location: profile.farm_location,
        produce_types: profile.produce_types,
        crops: profile.crops,
        livestock: profile.livestock,
        certifications: profile.certifications
      }
    end

    def serialize_trucking_company(company)
      {
        id: company.id,
        company_name: company.company_name,
        fleet_size: company.fleet_size,
        contact_person: company.contact_person,
        vehicle_types: company.vehicle_types
      }
    end

    def serialize_market_profile(profile)
      {
        id: profile.id,
        market_name: profile.market_name,
        market_type: profile.market_type,
        location: profile.location,
        preferred_produces: profile.preferred_produces
      }
    end

    def next_step_for(user)
      if user.profile_complete?
        '/api/v1/dashboard'
      else
        case user.user_role.to_sym
        when :farmer
          '/api/v1/farmer_profiles/complete'
        when :trucker
          '/api/v1/trucking_companies/complete'
        when :market
          '/api/v1/market_profiles/complete'
        else
          '/api/v1/profile/complete'
        end
      end
    end

    def format_validation_errors(resource)
      errors = {}
      
      resource.errors.each do |error|
        field = error.attribute
        errors[field] ||= []
        errors[field] << error.message
      end
      
      # Include nested profile errors
      if resource.farmer_profile&.errors&.any?
        errors[:farmer_profile] = format_nested_errors(resource.farmer_profile)
      elsif resource.trucking_company&.errors&.any?
        errors[:trucking_company] = format_nested_errors(resource.trucking_company)
      elsif resource.market_profile&.errors&.any?
        errors[:market_profile] = format_nested_errors(resource.market_profile)
      end
      
      errors
    end

    def format_nested_errors(profile)
      nested_errors = {}
      profile.errors.each do |error|
        field = error.attribute
        nested_errors[field] ||= []
        nested_errors[field] << error.message
      end
      nested_errors
    end

    def process_nested_attributes(params)
      user_role = params[:user_role]
      
      case user_role&.to_sym
      when :farmer
        process_farmer_profile(params)
      when :trucker
        process_trucking_company(params)
      when :market
        process_market_profile(params)
      end
    end

    def process_farmer_profile(params)
      return unless params[:farmer_profile_attributes].present?
      
      profile_params = params[:farmer_profile_attributes]
      
      if profile_params[:farm_location].present?
        if profile_params[:farm_location].is_a?(String)
          profile_params[:farm_location] = { 'address' => profile_params[:farm_location] }
        elsif profile_params[:farm_location].is_a?(Hash) || profile_params[:farm_location].is_a?(ActionController::Parameters)
          profile_params[:farm_location] = {
            'address' => profile_params[:farm_location][:address] || profile_params[:farm_location]['address'],
            'lat' => profile_params[:farm_location][:lat] || profile_params[:farm_location]['lat'],
            'lng' => profile_params[:farm_location][:lng] || profile_params[:farm_location]['lng']
          }.compact
        end
      end
      
      profile_params[:produce_types] = Array(profile_params[:produce_types]).reject(&:blank?)
      profile_params[:crops] = Array(profile_params[:crops]).reject(&:blank?)
      profile_params[:livestock] = Array(profile_params[:livestock]).reject(&:blank?)
      profile_params[:certifications] = Array(profile_params[:certifications]).reject(&:blank?)
    end

    def process_trucking_company(params)
      return unless params[:trucking_company_attributes].present?
      
      company_params = params[:trucking_company_attributes]
      
      if company_params[:registration_numbers].present?
        if company_params[:registration_numbers].is_a?(String)
          company_params[:registration_numbers] = company_params[:registration_numbers].split(/[\n,]/).map(&:strip).reject(&:blank?)
        elsif company_params[:registration_numbers].is_a?(Array)
          company_params[:registration_numbers] = company_params[:registration_numbers].reject(&:blank?)
        end
      else
        company_params[:registration_numbers] = []
      end
      
      if company_params[:routes].present? && company_params[:routes].is_a?(Array)
        company_params[:routes] = company_params[:routes].map do |route|
          next if route.is_a?(Hash) && route.values.all?(&:blank?)
          
          if route.is_a?(Hash)
            {
              'from' => route[:from] || route['from'],
              'to' => route[:to] || route['to'],
              'distance' => (route[:distance] || route['distance']).to_i
            }.compact
          else
            route
          end
        end.compact
      else
        company_params[:routes] = []
      end
      
      if company_params[:rates].present? && company_params[:rates].is_a?(Array)
        company_params[:rates] = company_params[:rates].map do |rate|
          next if rate.is_a?(Hash) && rate.values.all?(&:blank?)
          
          if rate.is_a?(Hash)
            {
              'type' => rate[:type] || rate['type'],
              'rate' => (rate[:rate] || rate['rate']).to_f,
              'currency' => rate[:currency] || rate['currency'] || 'ZAR'
            }.compact
          else
            rate
          end
        end.compact
      else
        company_params[:rates] = []
      end
      
      company_params[:vehicle_types] = Array(company_params[:vehicle_types]).reject(&:blank?)
    end

    def process_market_profile(params)
      return unless params[:market_profile_attributes].present?
      
      profile_params = params[:market_profile_attributes]
      
      if profile_params[:location].present?
        location_data = profile_params[:location]
        
        if location_data.is_a?(ActionController::Parameters) || location_data.is_a?(Hash)
          address = location_data[:address] || location_data['address']
          lat = location_data[:lat] || location_data['lat']
          lng = location_data[:lng] || location_data['lng']
          
          if address.present?
            profile_params[:location] = {
              'address' => address.to_s.strip,
              'lat' => lat.present? ? lat.to_f : nil,
              'lng' => lng.present? ? lng.to_f : nil
            }.compact
          else
            profile_params[:location] = nil
          end
        elsif location_data.is_a?(String)
          profile_params[:location] = { 'address' => location_data.strip }
        end
      end
      
      if profile_params[:preferred_produces].present?
        profile_params[:preferred_produces] = Array(profile_params[:preferred_produces]).reject(&:blank?)
      else
        profile_params[:preferred_produces] = []
      end
      
      [:organic_certified, :gap_certified, :haccp_certified].each do |field|
        if profile_params.key?(field)
          profile_params[field] = ActiveRecord::Type::Boolean.new.cast(profile_params[field])
        end
      end
    end

    def json_request?
      request.format.json?
    end
  end
end