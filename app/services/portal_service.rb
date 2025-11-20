# app/services/portal_service.rb
class PortalService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def data
    case user.user_role
    when 'farmer' then farmer_view
    when 'trucker' then trucker_view
    when 'market' then market_view
    else {}
    end
  end

  private

  def farmer_view
    {
      truckers: User.truckers.includes(:trucking_company).map { |t| serialize_trucker(t) },
      markets: User.markets.includes(:market_profile).map { |m| serialize_market(m) }
    }
  end

  def trucker_view
    {
      farmers: User.farmers.includes(:farmer_profile).map { |f| serialize_farmer(f) },
      markets: User.markets.includes(:market_profile).map { |m| serialize_market(m) }
    }
  end

  def market_view
    {
      farmers: User.farmers.includes(:farmer_profile).map { |f| serialize_farmer(f) },
      truckers: User.truckers.includes(:trucking_company).map { |t| serialize_trucker(t) }
    }
  end

  # Serializers
  def serialize_farmer(u)
    {
      id: u.id,
      name: u.farmer_profile&.full_name || 'Unnamed',
      phone_number: u.phone_number,
      farm_name: u.farmer_profile&.farm_name
    }
  end

  def serialize_trucker(u)
    {
      id: u.id,
      company_name: u.trucking_company&.company_name || 'Unnamed',
      phone_number: u.phone_number,
      vehicle_types: u.trucking_company&.vehicle_types
    }
  end

  def serialize_market(u)
    {
      id: u.id,
      market_name: u.market_profile&.market_name || 'Unnamed',
      phone_number: u.phone_number,
      market_type: u.market_profile&.market_type
    }
  end
end
