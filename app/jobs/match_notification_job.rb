class MatchNotificationJob < ApplicationJob
  queue_as :default

  def perform(produce_listing_id)
    produce_listing = ProduceListing.find(produce_listing_id)
    
    # Notify interested markets about the new listing
    NotificationService.notify_markets_of_new_listing(produce_listing)
    
    # Send email notifications to highly matched markets
    matching_service = ProduceMatchingService.new(nil)
    
    MarketProfile.joins(:user)
                 .where('preferred_produces @> ARRAY[?]::text[]', produce_listing.produce_type)
                 .find_each do |market|
      
      score = ProduceMatchingService.new(market).calculate_match_score(produce_listing)
      
      # Only send email for high-score matches to avoid spam
      if score > 15
        MatchNotificationMailer.new_match(market, produce_listing).deliver_now
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "MatchNotificationJob failed: #{e.message}"
  end
end