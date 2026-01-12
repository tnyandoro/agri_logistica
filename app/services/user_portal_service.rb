# app/services/user_portal_service.rb
class UserPortalService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Portal view: who the current user can see
  def portal_data
    case user.user_role
    when 'farmer' then farmer_portal
    when 'trucker' then trucker_portal
    when 'market' then market_portal
    else {}
    end
  end

  # Dashboard data: more detailed stats
  def dashboard_data
    case user.user_role
    when 'farmer' then farmer_dashboard
    when 'trucker' then trucker_dashboard
    when 'market' then market_dashboard
    else { error: 'Invalid user role' }
    end
  end

  private

  # === Portal methods ===
  def farmer_portal
    {
      truckers: serialize_users(User.truckers.includes(:trucking_company), :trucker),
      markets: serialize_users(User.markets.includes(:market_profile), :market)
    }
  end

  def trucker_portal
    {
      farmers: serialize_users(User.farmers.includes(:farmer_profile), :farmer),
      markets: serialize_users(User.markets.includes(:market_profile), :market)
    }
  end

  def market_portal
    {
      farmers: serialize_users(User.farmers.includes(:farmer_profile), :farmer),
      truckers: serialize_users(User.truckers.includes(:trucking_company), :trucker)
    }
  end

  # === Dashboard methods ===
  def farmer_dashboard
    profile = user.farmer_profile
    return { error: 'Farmer profile not found' } unless profile

    recent_listings = profile.produce_listings.recent.limit(5)
    total_listings = profile.produce_listings.count
    active_requests = ProduceRequest.joins(:produce_listing)
                                   .where(produce_listings: { farmer_profile: profile })
                                   .where(status: :pending)
                                   .count
    total_earnings = ProduceRequest.joins(:produce_listing)
                                  .where(produce_listings: { farmer_profile: profile })
                                  .where(status: :completed)
                                  .sum('produce_requests.quantity * produce_requests.price_offered')

    produce_summary = profile.produce_listings.group(:produce_type).sum(:quantity)

    monthly_earnings = ProduceRequest.joins(:produce_listing)
                                    .where(produce_listings: { farmer_profile: profile })
                                    .where(status: :completed)
                                    .where("produce_requests.created_at >= ?", 6.months.ago.beginning_of_month)
                                    .group_by_month('produce_requests.created_at', last: 6, format: "%b %Y")
                                    .sum('produce_requests.quantity * produce_requests.price_offered')

    {
      user_role: 'farmer',
      profile: serialize_user(user, :farmer),
      statistics: {
        total_listings: total_listings,
        active_requests: active_requests,
        total_earnings: total_earnings.to_f
      },
      recent_listings: recent_listings.map { |l| serialize_listing(l) },
      charts: {
        produce_summary: produce_summary.map { |type, qty| { produce_type: type, quantity: qty } },
        monthly_earnings: monthly_earnings.map { |month, amount| { month: month, earnings: amount.to_f } }
      },
      unread_notifications: user.notifications.unread.count
    }
  end

  def trucker_dashboard
    profile = user.trucking_company
    return { error: 'Trucking company profile not found' } unless profile

    available_shipments = Shipment.available_for_bidding.limit(10)
    active_bids = profile.shipment_bids.pending.count
    completed_shipments = profile.shipments.where(status: :delivered).count
    active_shipments = profile.shipments.active

    {
      user_role: 'trucker',
      profile: serialize_user(user, :trucker),
      statistics: {
        active_bids: active_bids,
        completed_shipments: completed_shipments,
        active_shipments_count: active_shipments.count
      },
      available_shipments: available_shipments.map { |s| serialize_shipment(s) },
      active_shipments: active_shipments.map { |s| serialize_shipment(s) },
      unread_notifications: user.notifications.unread.count
    }
  end

  def market_dashboard
    profile = user.market_profile
    return { error: 'Market profile not found' } unless profile

    matching_service = ProduceMatchingService.new(profile)
    recommended_listings = matching_service.find_matches.limit(8)
    active_requests = profile.produce_requests.active.count
    recent_requests = profile.produce_requests.recent.limit(5)

    {
      user_role: 'market',
      profile: serialize_user(user, :market),
      statistics: {
        active_requests: active_requests,
        total_requests: profile.produce_requests.count
      },
      recommended_listings: recommended_listings.map { |l| serialize_listing(l) },
      recent_requests: recent_requests.map { |r| serialize_request(r) },
      unread_notifications: user.notifications.unread.count
    }
  end

  # === Serialization helpers ===
  def serialize_users(users, role)
    users.map { |u| serialize_user(u, role) }
  end

  def serialize_user(u, role)
    base = u.as_json(only: [:id, :email, :phone_number])
    profile_data = case role
                   when :farmer
                     u.farmer_profile&.slice(:full_name, :farm_name, :farm_location)
                   when :trucker
                     u.trucking_company&.slice(:company_name, :vehicle_types)
                   when :market
                     u.market_profile&.slice(:market_name, :market_type, :location)
                   end
    base.merge(profile_data: profile_data)
  end

  def serialize_listing(listing)
    {
      id: listing.id,
      produce_type: listing.produce_type,
      quantity: listing.quantity,
      unit: listing.unit,
      price_per_unit: listing.price_per_unit,
      available_from: listing.available_from,
      available_until: listing.available_until,
      status: listing.status,
      farmer: {
        id: listing.farmer_profile.id,
        name: listing.farmer_profile.name,
        location: listing.farmer_profile.location
      }
    }
  end

  def serialize_shipment(shipment)
    {
      id: shipment.id,
      status: shipment.status,
      pickup_location: shipment.pickup_location,
      delivery_location: shipment.delivery_location,
      pickup_date: shipment.pickup_date,
      delivery_date: shipment.delivery_date
    }
  end

  def serialize_request(request)
    {
      id: request.id,
      quantity: request.quantity,
      price_offered: request.price_offered,
      status: request.status,
      delivery_date: request.delivery_date
    }
  end
end
