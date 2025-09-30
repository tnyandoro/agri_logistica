class DailySummaryMailer < ApplicationMailer
    def farmer_summary(user, data)
      @user = user
      @farmer = user.farmer_profile
      @new_requests = data[:new_requests]
      @active_listings = data[:active_listings]
      
      mail(
        to: user.email,
        subject: "📊 Daily Summary: #{@new_requests} new requests"
      )
    end
  
    def market_summary(user, data)
      @user = user
      @market = user.market_profile
      @new_matches = data[:new_matches]
      @recommended_listings = data[:recommended_listings]
      
      mail(
        to: user.email,
        subject: "🌟 Daily Summary: #{@new_matches} new matches found"
      )
    end
  
    def trucker_summary(user, data)
      @user = user
      @trucker = user.trucking_company
      @available_shipments = data[:available_shipments]
      @active_bids = data[:active_bids]
      
      mail(
        to: user.email,
        subject: "🚛 Daily Summary: #{@available_shipments} shipments available"
      )
    end
  end