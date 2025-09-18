class FarmerProfile < ApplicationRecord
  belongs_to :user
  has_many :produce_listings, dependent: :destroy
  
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :farm_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :farm_location, presence: true
  validates :produce_types, presence: true
  
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  PRODUCE_TYPES = [
    'Crops', 'Livestock', 'Dairy', 'Poultry', 'Fruits', 
    'Vegetables', 'Grains', 'Organic', 'Herbs', 'Nuts'
  ].freeze

  CROPS = [
    'Wheat', 'Corn', 'Rice', 'Barley', 'Oats', 'Soybeans',
    'Tomatoes', 'Potatoes', 'Carrots', 'Lettuce', 'Spinach',
    'Apples', 'Oranges', 'Bananas', 'Berries'
  ].freeze

  LIVESTOCK = [
    'Cattle', 'Poultry', 'Sheep', 'Goats', 'Pigs', 'Fish'
  ].freeze

  def address
    farm_location&.dig('address')
  end

  def latitude_longitude
    [latitude, longitude] if latitude.present? && longitude.present?
  end

  def active_listings_count
    produce_listings.where(status: :available).count
  end

  private

  def address_changed?
    farm_location_changed? && farm_location&.dig('address').present?
  end

  def geocode
    address = farm_location['address']
    if address.present?
      coords = Geocoder.coordinates(address)
      if coords
        self.latitude = coords[0]
        self.longitude = coords[1]
        self.farm_location = farm_location.merge({
          'lat' => coords[0],
          'lng' => coords[1]
        })
      end
    end
  end
end