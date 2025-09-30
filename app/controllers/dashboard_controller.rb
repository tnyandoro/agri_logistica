class DashboardController < ApplicationController
    before_action :authenticate_user!
  
    def index
      @profile = current_user.profile
      
      case current_user.user_role
      when 'farmer'
        farmer_dashboard
      when 'trucker'
        trucker_dashboard
      when 'market'
        market_dashboard
      end
      
      @unread_notifications_count = current_user.notifications.unread.count
    end
  
    private
  
    def farmer_dashboard
      @recent_listings = @profile.produce_listings.recent.limit(5)
      @total_listings = @profile.produce_listings.count
      @active_requests = ProduceRequest.joins(:produce_listing)
                                     .where(produce_listings: { farmer_profile: @profile })
                                     .where(status: :pending)
                                     .count
      @total_earnings = ProduceRequest.joins(:produce_listing)
                                    .where(produce_listings: { farmer_profile: @profile })
                                    .where(status: :completed)
                                    .sum('quantity * price_offered')
    end
  
    def trucker_dashboard
      @available_shipments = Shipment.available_for_bidding
                                    .includes(:produce_listing, :produce_request)
                                    .limit(10)
      @active_bids = @profile.shipment_bids.pending.count
      @completed_shipments = @profile.shipments.where(status: :delivered).count
      @active_shipments = @profile.shipments.active.includes(:produce_listing, :produce_request)
    end
  
    def market_dashboard
      @matching_service = ProduceMatchingService.new(@profile)
      @recommended_listings = @matching_service.find_matches.limit(8)
      @active_requests = @profile.produce_requests.active.count
      @recent_requests = @profile.produce_requests.recent.includes(:produce_listing).limit(5)
    end
  end