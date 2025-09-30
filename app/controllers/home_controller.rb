class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]  # Add this line
  
  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      @recent_listings = ProduceListing.available_now.recent.includes(:farmer_profile).limit(6)
      @total_farmers = FarmerProfile.count
      @total_markets = MarketProfile.count
      @total_truckers = TruckingCompany.count
    end
  end
end