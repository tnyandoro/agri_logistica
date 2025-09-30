class ProduceExpiryJob < ApplicationJob
    queue_as :default
  
    def perform
      # Find produce that expires in 2 days and notify relevant markets
      expiring_soon = ProduceListing.available_now
                                   .where(available_until: 2.days.from_now..3.days.from_now)
      
      expiring_soon.find_each do |listing|
        # Notify markets that have this produce in their preferred list
        interested_markets = MarketProfile.joins(:user)
                                         .where('preferred_produces @> ARRAY[?]::text[]', listing.produce_type)
        
        interested_markets.find_each do |market|
          matching_service = ProduceMatchingService.new(market)
          next unless matching_service.send(:within_reasonable_distance?, market, listing.farmer_profile)
          
          NotificationService.create_notification(
            user: market.user,
            title: "Produce expiring soon - Great deal!",
            message: "#{listing.title} from #{listing.farmer_profile.farm_name} expires in 2 days. Price: $#{listing.price_per_unit}/#{listing.unit}",
            notification_type: :match,
            data: { produce_listing_id: listing.id, urgent: true }
          )
        end
      end
      
      # Mark expired listings
      expired_listings = ProduceListing.where(status: :available)
                                      .where('available_until < ?', Date.current)
      
      expired_listings.update_all(status: :expired)
      
      # Schedule next run
      ProduceExpiryJob.set(wait: 1.day).perform_later
    end
  end