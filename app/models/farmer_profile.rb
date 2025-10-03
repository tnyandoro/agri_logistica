# frozen_string_literal: true
class FarmerProfile < ApplicationRecord
  belongs_to :user
  has_many :produce_listings, dependent: :destroy
  
  # NO serialize needed - PostgreSQL handles arrays and JSON natively
  # Set defaults for arrays and hashes
  attribute :produce_types, :string, array: true, default: []
  attribute :crops, :string, array: true, default: []
  attribute :livestock, :string, array: true, default: []
  attribute :certifications, :string, array: true, default: []
  attribute :farm_location, :json, default: {}
  
  # Conditional validations - skip during user signup
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }, 
            unless: :skip_validation?
  validates :farm_name, presence: true, length: { minimum: 2, maximum: 100 }, 
            unless: :skip_validation?
  validates :farm_location, presence: true, unless: :skip_validation?
  validates :produce_types, presence: true, unless: :skip_validation?
  validates :production_capacity, numericality: { greater_than: 0 }, 
            allow_nil: true, unless: :skip_validation?
  
  # Geocoding - only when address is present and changed
  geocoded_by :address
  after_validation :geocode, if: :should_geocode?

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

  # Helper to display produce types as comma-separated string
  def produce_types_display
    return '' unless produce_types.present?
    produce_types.join(', ')
  end

  # Helper to display crops as comma-separated string
  def crops_display
    return '' unless crops.present?
    crops.join(', ')
  end

  # Helper to display livestock as comma-separated string
  def livestock_display
    return '' unless livestock.present?
    livestock.join(', ')
  end

  private

  # Skip validation if:
  # 1. User is being created (new_record)
  # 2. All key fields are blank (profile not filled yet)
  def skip_validation?
    user&.new_record? || all_fields_blank?
  end

  def all_fields_blank?
    full_name.blank? && farm_name.blank? && farm_location.blank?
  end

  # Only geocode if:
  # 1. Address has changed
  # 2. We're not in the middle of user creation (skip_validation)
  def should_geocode?
    address_changed? && !skip_validation?
  end

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
  rescue StandardError => e
    Rails.logger.error "Geocoding failed for FarmerProfile #{id}: #{e.message}"
    # Don't fail the save if geocoding fails
  end
end