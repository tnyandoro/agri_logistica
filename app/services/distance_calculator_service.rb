class DistanceCalculatorService
    EARTH_RADIUS_KM = 6371
  
    def self.calculate(lat1, lng1, lat2, lng2)
      return 0 if lat1.nil? || lng1.nil? || lat2.nil? || lng2.nil?
      
      # Convert degrees to radians
      rad_per_deg = Math::PI / 180
      rlat1 = lat1 * rad_per_deg
      rlng1 = lng1 * rad_per_deg
      rlat2 = lat2 * rad_per_deg
      rlng2 = lng2 * rad_per_deg
      
      # Haversine formula
      dlat = rlat2 - rlat1
      dlng = rlng2 - rlng1
      
      a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      
      distance = EARTH_RADIUS_KM * c
      distance.round(2)
    end
  
    def self.within_radius?(center_lat, center_lng, point_lat, point_lng, radius_km)
      distance = calculate(center_lat, center_lng, point_lat, point_lng)
      distance <= radius_km
    end
  
    def self.calculate_shipping_cost(distance_km, base_rate_per_km = 2.0, cargo_type = 'general')
      return 0 if distance_km <= 0
      
      # Base cost calculation
      base_cost = distance_km * base_rate_per_km
      
      # Apply cargo type multipliers
      multiplier = case cargo_type.downcase
                  when 'refrigerated', 'perishable' then 1.5
                  when 'livestock' then 1.8
                  when 'fragile' then 1.3
                  when 'bulk' then 0.8
                  else 1.0
                  end
      
      # Minimum charge
      minimum_charge = 50.0
      
      total_cost = base_cost * multiplier
      [total_cost, minimum_charge].max.round(2)
    end
  end