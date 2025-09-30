class MatchNotificationMailer < ApplicationMailer
  def new_match(market_profile, produce_listing)
    @market = market_profile
    @listing = produce_listing
    @farmer = produce_listing.farmer_profile
    @distance = calculate_distance if both_have_coordinates?
    
    mail(
      to: @market.user.email,
      subject: "🌱 New produce match: #{@listing.title} from #{@farmer.farm_name}"
    )
  end

  private

  def both_have_coordinates?
    @market.latitude.present? && @market.longitude.present? &&
    @farmer.latitude.present? && @farmer.longitude.present?
  end

  def calculate_distance
    DistanceCalculatorService.calculate(
      @market.latitude, @market.longitude,
      @farmer.latitude, @farmer.longitude
    )
  end
end