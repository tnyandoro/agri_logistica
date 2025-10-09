module Api
    module V1
        class Api::V1::SearchController < BaseController
        skip_before_action :authenticate_api_user!, only: [:index]
        skip_before_action :check_profile_completion
  
        # GET /api/v1/search
        def index
          query = params[:q]
          category = params[:category] # 'produce', 'markets', 'truckers', 'all'
          
          results = {
            produce_listings: [],
            markets: [],
            truckers: []
          }
          
          if query.present?
            case category
            when 'produce'
              results[:produce_listings] = search_produce(query)
            when 'markets'
              results[:markets] = search_markets(query)
            when 'truckers'
              results[:truckers] = search_truckers(query)
            else
              results[:produce_listings] = search_produce(query)
              results[:markets] = search_markets(query)
              results[:truckers] = search_truckers(query)
            end
          end
          
          render json: {
            success: true,
            query: query,
            data: results
          }
        end
  
        private
  
        def search_produce(query)
          ProduceListing.where(status: 'active')
                       .where("produce_type ILIKE ? OR description ILIKE ? OR location ILIKE ?", 
                              "%#{query}%", "%#{query}%", "%#{query}%")
                       .limit(10)
                       .map { |l| ProduceListingSerializer.new(l, include_farmer: true).as_json }
        end
  
        def search_markets(query)
          MarketProfile.joins(:user)
                      .where("market_name ILIKE ? OR location ILIKE ? OR market_type ILIKE ?",
                             "%#{query}%", "%#{query}%", "%#{query}%")
                      .limit(10)
                      .map { |m| MarketProfileSerializer.new(m).as_json }
        end
  
        def search_truckers(query)
          TruckingCompany.joins(:user)
                        .where("company_name ILIKE ? OR vehicle_type ILIKE ? OR service_areas ILIKE ?",
                               "%#{query}%", "%#{query}%", "%#{query}%")
                        .limit(10)
                        .map { |t| TruckingCompanySerializer.new(t).as_json }
        end
      end
    end
  end