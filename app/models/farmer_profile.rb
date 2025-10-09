# frozen_string_literal: true
class FarmerProfile < ApplicationRecord
  belongs_to :user
  has_many :produce_listings, dependent: :destroy

  # PostgreSQL arrays and JSON defaults
  attribute :produce_types, :string, array: true, default: []
  attribute :crops, :string, array: true, default: []
  attribute :livestock, :string, array: true, default: []
  attribute :certifications, :string, array: true, default: []
  attribute :farm_location, :json, default: {}

  # Validations
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }, unless: :skip_validation?
  validates :farm_name, presence: true, length: { minimum: 2, maximum: 100 }, unless: :skip_validation?
  validates :farm_location, presence: true, unless: :skip_validation?
  validates :produce_types, presence: true, unless: :skip_validation?
  validates :production_capacity, numericality: { greater_than: 0 }, allow_nil: true, unless: :skip_validation?

  # Geocoding
  geocoded_by :address
  after_validation :geocode, if: :should_geocode?

  # ---------- Public Methods ----------

  def address
    farm_location&.dig('address')
  end

  def produce_types_display
    produce_types.present? ? produce_types.join(', ') : ''
  end

  # Returns a hash of monthly earnings for the last 6 months
  def monthly_earnings
    ProduceRequest.joins(:produce_listing)
                  .where(produce_listings: { farmer_profile_id: id })
                  .where(status: :completed)
                  .where("produce_requests.created_at >= ?", 6.months.ago.beginning_of_month)
                  .group_by_month('produce_requests.created_at', last: 6, format: "%b %Y")
                  .sum('produce_requests.quantity * produce_requests.price_offered')
  end

  # Returns a human-friendly display name for the farmer or farm
  def name
    full_name.presence || farm_name.presence || "Unnamed Farmer"
  end
  
  def location
    {
      address: farm_location&.dig('address'),
      lat: farm_location&.dig('lat'),
      lng: farm_location&.dig('lng')
    }
  end


  private

  def skip_validation?
    user&.new_record? || all_fields_blank?
  end

  def all_fields_blank?
    full_name.blank? && farm_name.blank? && farm_location.blank?
  end

  def should_geocode?
    address_changed? && !skip_validation?
  end

  def address_changed?
    farm_location_changed? && farm_location&.dig('address').present?
  end

  def geocode
    addr = farm_location['address']
    if addr.present?
      coords = Geocoder.coordinates(addr)
      if coords
        self.latitude = coords[0]
        self.longitude = coords[1]
        self.farm_location = farm_location.merge('lat' => coords[0], 'lng' => coords[1])
      end
    end
  rescue StandardError => e
    Rails.logger.error "Geocoding failed for FarmerProfile #{id}: #{e.message}"
  end
end
