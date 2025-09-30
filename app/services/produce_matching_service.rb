class ProduceMatchingService
    def initialize(market_profile)
      @market = market_profile
    end
  
    def find_matches(produce_type: nil, max_distance: 100, limit: 20)
      query = ProduceListing.available_now.includes(:farmer_profile)
      
      # Filter by produce type
      if produce_type.present?
        query = query.by_produce_type(produce_type)
      else
        query = query.where(produce_type: @market.preferred_produces)
      end
  
      # Filter by distance if market has location
      if @market.latitude.present? && @market.longitude.present?
        query = filter_by_distance(query, max_distance)
      end
  
      # Order by relevance (price, distance, freshness)
      query.order(calculate_relevance_order)
           .limit(limit)
    end
  
    def find_urgent_matches
      # Find produce that expires soon and matches market preferences
      ProduceListing.available_now
                    .where(produce_type: @market.preferred_produces)
                    .where('available_until <= ?', 3.days.from_now)
                    .order(:available_until)
                    .limit(10)
    end
  
    def calculate_match_score(listing)
      score = 0
      
      # Produce type match
      score += 10 if @market.preferred_produces.include?(listing.produce_type)
      
      # Distance factor (closer is better)
      if @market.latitude && listing.farmer_profile.latitude
        distance = calculate_distance(
          @market.latitude, @market.longitude,
          listing.farmer_profile.latitude, listing.farmer_profile.longitude
        )
        score += [10 - (distance / 10), 0].max  # Max 10 points for distance
      end
      
      # Price factor (reasonable pricing gets points)
      average_price = ProduceListing.where(produce_type: listing.produce_type)
                                   .average(:price_per_unit) || listing.price_per_unit
      price_ratio = listing.price_per_unit / average_price
      score += [5 - (price_ratio - 1) * 5, 0].max  # Max 5 points for competitive pricing
      
      # Availability factor (longer availability is better)
      days_available = (listing.available_until - Date.current).to_i
      score += [days_available / 2, 5].min  # Max 5 points for availability
      
      # Organic bonus
      score += 3 if listing.organic?
      
      score.round(2)
    end
  
    private
  
    def filter_by_distance(query, max_distance_km)
      # Using simple bounding box for performance
      # In production, consider using PostGIS for more accurate distance calculations
      lat_range = max_distance_km / 111.0  # Approximate km per degree of latitude
      lng_range = max_distance_km / (111.0 * Math.cos(@market.latitude * Math::PI / 180))
      
      query.joins(:farmer_profile)
           .where(
             farmer_profiles: {
               latitude: (@market.latitude - lat_range)..(@market.latitude + lat_range),
               longitude: (@market.longitude - lng_range)..(@market.longitude + lng_range)
             }
           )
    end
  
    def calculate_relevance_order
      # Order by a combination of factors
      Arel.sql('
        CASE 
          WHEN organic = true THEN 1 ELSE 0 
        END DESC,
        price_per_unit ASC,
        available_until DESC
      ')
    end
  
    def calculate_distance(lat1, lng1, lat2, lng2)
      # Haversine formula for calculating distance between two coordinates
      rad_per_deg = Math::PI / 180
      rlat1, rlng1, rlat2, rlng2 = [lat1, lng1, lat2, lng2].map { |d| d * rad_per_deg }
      
      dlat = rlat2 - rlat1
      dlng = rlng2 - rlng1
      
      a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      
      6371 * c  # Earth's radius in kilometers
    end
  end