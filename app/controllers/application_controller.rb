class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: [:index, :show]
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_profile_completion, if: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone])
  end

  private

  def check_profile_completion
    return unless user_signed_in?
    return if controller_name == 'registrations' && action_name.in?(['complete_profile', 'update_profile'])
    return if request.path.in?(['/users/sign_out', '/complete_profile', '/update_profile'])
    
    if current_user.profile && profile_incomplete?
      redirect_to complete_profile_path, alert: 'Please complete your profile to continue.'
    end
  end

  def profile_incomplete?
    profile = current_user.profile
    return true unless profile
    
    case current_user.role
    when 'farmer'
      profile.full_name.blank? || profile.farm_name.blank? || profile.farm_location.blank? || profile.produce_types.empty?
    when 'trucker'
      profile.company_name.blank? || profile.vehicle_types.empty? || profile.registration_numbers.empty?
    when 'market'
      profile.market_name.blank? || profile.location.blank? || profile.preferred_produces.empty?
    end
  end
end