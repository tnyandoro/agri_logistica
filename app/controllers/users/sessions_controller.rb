# frozen_string_literal: true
module Users
  class SessionsController < Devise::SessionsController
    respond_to :json
    
    # Skip CSRF protection for API
    skip_before_action :verify_authenticity_token, if: :json_request?

    private

    def respond_with(resource, _opts = {})
      token = generate_jwt_token(resource)
      
      render json: {
        message: 'Logged in successfully.',
        token: token,
        token_type: 'Bearer',
        expires_in: 24.hours.to_i,
        user: user_data(resource)
      }, status: :ok
    end

    def respond_to_on_destroy
      if request.headers['Authorization'].present?
        # In a production app, you might want to blacklist the token here
        render json: {
          message: 'Logged out successfully.'
        }, status: :ok
      else
        render json: {
          message: "Couldn't find an active session."
        }, status: :unauthorized
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
      {
        id: user.id,
        email: user.email,
        phone_number: user.phone_number,
        user_role: user.user_role,
        profile_complete: user.profile_complete?,
        created_at: user.created_at,
        dashboard_url: dashboard_url_for(user)
      }
    end

    # Return the appropriate dashboard URL based on user role
    def dashboard_url_for(user)
      case user.user_role
      when 'farmer'
        '/api/v1/dashboard'
      when 'trucker'
        '/api/v1/dashboard'
      when 'market'
        '/api/v1/dashboard'
      else
        '/api/v1/dashboard'
      end
    end

    def json_request?
      request.format.json?
    end
  end
end