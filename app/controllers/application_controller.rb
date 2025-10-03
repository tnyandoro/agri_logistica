class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Skip authentication for Devise controllers
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_profile_completion, if: :user_signed_in?, unless: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number, :user_role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number, :user_role])
  end

  private

  def check_profile_completion
    return unless user_signed_in?
    return if request.path.in?([destroy_user_session_path, complete_profile_path, update_profile_path, dashboard_path])

    if profile_incomplete?
      redirect_to complete_profile_path, alert: 'Please complete your profile to continue.'
    end
  end

  def profile_incomplete?
    return true unless current_user&.profile

    case current_user.user_role
    when 'farmer'
      profile = current_user.farmer_profile
      profile.full_name.blank? ||
        profile.farm_name.blank? ||
        profile.farm_location.blank? ||
        profile.produce_types.blank?
    when 'trucker'
      profile = current_user.trucking_company
      profile.company_name.blank? ||
        profile.vehicle_types.blank? ||
        profile.registration_numbers.blank?
    when 'market'
      profile = current_user.market_profile
      profile.market_name.blank? ||
        profile.location.blank? ||
        profile.preferred_produces.blank?
    else
      true
    end
  end
end