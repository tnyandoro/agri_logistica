class GeocodingService
    def self.geocode_address(address)
      return { lat: nil, lng: nil, formatted_address: address } if address.blank?
      
      begin
        coordinates = Geocoder.coordinates(address)
        formatted_address = Geocoder.address(coordinates) if coordinates
        
        {
          lat: coordinates&.first,
          lng: coordinates&.last,
          formatted_address: formatted_address || address
        }
      rescue => e
        Rails.logger.error "Geocoding failed for address '#{address}': #{e.message}"
        { lat: nil, lng: nil, formatted_address: address }
      end
    end
  
    def self.reverse_geocode(lat, lng)
      return nil if lat.blank? || lng.blank?
      
      begin
        Geocoder.address([lat, lng])
      rescue => e
        Rails.logger.error "Reverse geocoding failed for coordinates [#{lat}, #{lng}]: #{e.message}"
        nil
      end
    end
  end