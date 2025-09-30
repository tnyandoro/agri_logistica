class DailySummaryJob < ApplicationJob
    queue_as :default
  
    def perform
      User.includes(:farmer_profile, :trucking_company, :market_profile).find_each do |user|
        case user.user_role
        when 'farmer'
          send_farmer_summary(user)
        when 'market'
          send_market_summary(user)
        when 'trucker'
          send_trucker_summary(user)
        end
      end
      
      # Schedule next run for tomorrow
      DailySummaryJob.set(wait: 1.day).perform_later
    end
  
    private
  
    def send_farmer_summary(user)
      profile = user.farmer_profile
      return unless profile
      
      # Get today's stats
      new_requests = ProduceRequest.joins(:produce_listing)
                                  .where(produce_listings: { farmer_profile: profile })
                                  .where('produce_requests.created_at >= ?', 1.day.ago)
                                  .count
      
      return if new_requests == 0
      
      DailySummaryMailer.farmer_summary(user, {
        new_requests: new_requests,
        active_listings: profile.produce_listings.available_now.count
      }).deliver_now
    end
  
    def send_market_summary(user)
      profile = user.market_profile
      return unless profile
      
      # Find new matching produce
      matching_service = ProduceMatchingService.new(profile)
      new_matches = ProduceListing.available_now
                                 .where('created_at >= ?', 1.day.ago)
                                 .where(produce_type: profile.preferred_produces)
                                 .count
      
      return if new_matches == 0
      
      DailySummaryMailer.market_summary(user, {
        new_matches: new_matches,
        recommended_listings: matching_service.find_matches(limit: 5)
      }).deliver_now
    end
  
    def send_trucker_summary(user)
      profile = user.trucking_company
      return unless profile
      
      # Get available shipments
      available_shipments = Shipment.available_for_bidding.count
      active_bids = profile.shipment_bids.pending.count
      
      return if available_shipments == 0 && active_bids == 0
      
      DailySummaryMailer.trucker_summary(user, {
        available_shipments: available_shipments,
        active_bids: active_bids
      }).deliver_now
    end
  end