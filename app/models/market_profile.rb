class MarketProfile < ApplicationRecord
  belongs_to :user
  has_many :produce_requests, dependent: :destroy
  
  validates :market_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :market_type, presence: true
  validates :location, presence: true
  validates :preferred_produces, presence: true
  
  enum :market_type, {  # FIXED: Added colon before market_type
    shop: 0, 
    supermarket: 1, 
    wholesale: 2, 
    processing_plant: 3, 
    restaurant: 4,
    export: 5,
    other: 6 
  }

  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  def address
    location&.dig('address')
  end

  def latitude_longitude
    [latitude, longitude] if latitude.present? && longitude.present?
  end

  def active_requests_count
    produce_requests.where(status: :pending).count
  end

  private

  def address_changed?
    location_changed? && location&.dig('address').present?
  end

  def geocode
    address = location['address']
    if address.present?
      coords = Geocoder.coordinates(address)
      if coords
        self.latitude = coords[0]
        self.longitude = coords[1]
        self.location = location.merge({
          'lat' => coords[0],
          'lng' => coords[1]
        })
      end
    end
  end
end