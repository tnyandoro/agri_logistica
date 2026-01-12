class ApplicationController < ActionController::Base
  include ActionController::MimeResponds

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :check_profile_completion

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number, :user_role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number, :user_role])
  end

  private

  def check_profile_completion
    return unless user_signed_in?

    skip_paths = [
      destroy_user_session_path,
      new_user_session_path,
      new_user_registration_path,
      dashboard_path,
      root_path
    ]

    skip_paths << complete_profile_path if respond_to?(:complete_profile_path)
    skip_paths << update_profile_path if respond_to?(:update_profile_path)

    return if request.path.in?(skip_paths)

    redirect_to dashboard_path, alert: 'Please complete your profile to continue.' if profile_incomplete?
  end

  def profile_incomplete?
    current_user && !current_user.profile_complete?
  end
end
