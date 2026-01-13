# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < Api::V1::BaseController
      skip_before_action :authenticate_api_user!, only: [:create]

      def create
        user = User.find_by(email: params.dig(:user, :email))

        if user&.valid_password?(params.dig(:user, :password))
          token = generate_jwt_token(user)

          render json: {
            message: 'Logged in successfully.',
            token: token,
            user: {
              id: user.id,
              email: user.email,
              phone_number: user.phone_number,
              user_role: user.user_role,
              profile_complete: user.profile_complete?
            }
          }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def destroy
        render json: { message: 'Logged out successfully.' }, status: :ok
      end

      private

      def generate_jwt_token(user)
        payload = {
          user_id: user.id,
          email: user.email,
          user_role: user.user_role,
          exp: 24.hours.from_now.to_i,
          iat: Time.now.to_i
        }

        JWT.encode(
          payload,
          Rails.application.credentials.secret_key_base || Rails.application.secret_key_base,
          'HS256'
        )
      end
    end
  end
end
