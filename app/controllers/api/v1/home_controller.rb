module Api
  module V1
    class HomeController < Api::V1::BaseController

      skip_before_action :authenticate_api_user!
      skip_before_action :check_profile_completion

      
      def index
        render json: {
          message: 'Welcome to Agricultural Logistics API',
          version: '1.0',
          documentation: '/api/docs',
          endpoints: {
            auth: {
              sign_up: { method: 'POST', path: '/users', description: 'Create a new user account' },
              sign_in: { method: 'POST', path: '/users/sign_in', description: 'Sign in to your account' },
              sign_out: { method: 'DELETE', path: '/users/sign_out', description: 'Sign out from your account' }
            },
            api: {
              base_url: '/api/v1',
              dashboard: '/api/v1/dashboard',
              produce_listings: '/api/v1/produce_listings',
              markets: '/api/v1/markets',
              truckers: '/api/v1/truckers'
            }
          },
          stats: {
            total_farmers: FarmerProfile.count,
            total_markets: MarketProfile.count,
            total_truckers: TruckingCompany.count,
            active_listings: ProduceListing.available_now.count
          },
          recent_listings: recent_listings_data
        }
      end

      private

      def recent_listings_data
        ProduceListing.available_now
                      .recent
                      .includes(:farmer_profile)
                      .limit(6)
                      .map do |listing|
          {
            id: listing.id,
            produce_type: listing.produce_type,
            quantity: listing.quantity,
            unit: listing.unit,
            price_per_unit: listing.price_per_unit,
            available_from: listing.available_from,
            available_until: listing.available_until,
            farmer: {
              id: listing.farmer_profile.id,
              name: listing.farmer_profile.name,
              location: listing.farmer_profile.location
            }
          }
        end
      end
    end
  end
end
