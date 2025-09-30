class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # before_action :authenticate_user!, except: [:index, :show]
  before_action :authenticate_user!, except: [:index]
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_profile_completion, if: :user_signed_in?

  protected

  # Permit additional Devise parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :user_role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone, :user_role])
  end

  private

  # Ensure user completes their profile before accessing most pages
  def check_profile_completion
    return unless user_signed_in?

    # Skip for Devise registration controller actions related to profile completion
    return if devise_controller? && action_name.in?(%w[complete_profile update_profile])
    return if request.path.in?([destroy_user_session_path, complete_profile_path, update_profile_path])

    if profile_incomplete?
      redirect_to complete_profile_path, alert: 'Please complete your profile to continue.'
    end
  end

  # Determines if the current user's profile is incomplete based on role
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
