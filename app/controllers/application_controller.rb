class ApplicationController < ActionController::Base
  include ActionController::MimeResponds
  
  protect_from_forgery with: :exception
  

  # Skip authentication for Devise controllers
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :check_profile_completion, if: :user_signed_in?, unless: :devise_or_public_controller?

  protected

  # This can be removed since RegistrationsController has more detailed configuration
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number, :user_role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number, :user_role])
  end

  private

   # For API, return JSON error responses
   def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end

  def devise_or_public_controller?
    devise_controller? || controller_name == 'pages' || action_name == 'welcome'
  end

  def check_profile_completion
    return unless user_signed_in?
    
    # Skip check for certain paths
    skip_paths = [
      destroy_user_session_path,
      new_user_session_path,
      new_user_registration_path,
      dashboard_path,
      root_path
    ]
    
    # Add dynamic paths if they exist
    skip_paths << complete_profile_path if respond_to?(:complete_profile_path)
    skip_paths << update_profile_path if respond_to?(:update_profile_path)
    
    return if request.path.in?(skip_paths)

    if profile_incomplete?
      redirect_to dashboard_path, alert: 'Please complete your profile to continue.'
    end
  end

  def profile_incomplete?
    return false unless current_user
    
    # Use the User model's built-in method
    !current_user.profile_complete?
  end
end