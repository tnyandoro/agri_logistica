module Api
  module V1
    class RegistrationsController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!, if: -> { action_name == 'create' }
      
      def create
        Rails.logger.info "=== Registration Params: #{user_params.inspect}"
        
        # Convert user_role string to the correct format for the enum
        processed_params = user_params.to_h
        if processed_params[:user_role].present?
          processed_params[:user_role] = processed_params[:user_role].to_sym
        end
        
        user = User.new(processed_params)
        
        Rails.logger.info "=== User valid? #{user.valid?}"
        Rails.logger.info "=== User errors: #{user.errors.full_messages}" unless user.valid?
        
        if user.save
          token = generate_jwt_token(user)
          render json: {
            user: {
              id: user.id,
              email: user.email,
              phone_number: user.phone_number,
              user_role: user.user_role
            },
            token: token,
            message: "Registration successful!"
          }, status: :created
        else
          Rails.logger.error "=== Registration failed with errors: #{user.errors.full_messages}"
          render json: { 
            errors: user.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def user_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :user_role,
          :phone_number,  # make sure phone_number is included
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
            :latitude,
            :longitude,
            location: [:address],
            preferred_produces: [] # << include this as an array
          ]
        )
      end

      def generate_jwt_token(user)
        JWT.encode(
          { 
            user_id: user.id, 
            exp: 24.hours.from_now.to_i 
          },
          Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
        )
      end
    end
  end
end