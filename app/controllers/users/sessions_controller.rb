# frozen_string_literal: true
module Users
  class SessionsController < Devise::SessionsController
    respond_to :json
    skip_before_action :verify_authenticity_token, if: :json_request?

    def create
      user = User.find_by(email: params[:user][:email])

      if user&.valid_password?(params[:user][:password])
        sign_in(user)

        render json: {
          message: "Logged in successfully.",
          token: generate_jwt_token(user),
          user: user_data(user)
        }, status: :ok
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def destroy
      render json: { message: "Logged out successfully." }, status: :ok
    end

    private

    def generate_jwt_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        user_role: user.user_role,
        exp: 24.hours.from_now.to_i
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
    end

    def user_data(user)
      {
        id: user.id,
        email: user.email,
        user_role: user.user_role,
        phone_number: user.phone_number,
        profile_complete: user.profile_complete?
      }
    end

    def json_request?
      request.format.json?
    end
  end
end
