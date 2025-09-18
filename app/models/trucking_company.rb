class TruckingCompany < ApplicationRecord
  belongs_to :user
  has_many :shipment_bids, dependent: :destroy
  has_many :shipments, dependent: :destroy
  
  validates :company_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :vehicle_types, presence: true
  validates :registration_numbers, presence: true
  validates :contact_person, presence: true
  
  VEHICLE_TYPES = [
    'Refrigerated Truck', 'Flatbed', 'Pickup', 'Box Truck', 
    'Semi-Trailer', 'Tanker', 'Livestock Trailer', 'Dry Van'
  ].freeze

  def available_routes_from(location)
    return [] unless routes.present? && location.present?
    routes.select { |route| route['from']&.downcase&.include?(location.downcase) }
  end

  def base_rate_per_km
    per_km_rate = rates.find { |r| r['type'] == 'per_km' }
    per_km_rate&.dig('rate')&.to_f || 2.0
  end

  def calculate_shipping_cost(distance_km, cargo_type = 'general')
    base_rate = base_rate_per_km
    
    # Adjust rate based on cargo type
    multiplier = case cargo_type.downcase
                when 'refrigerated', 'perishable' then 1.5
                when 'livestock' then 1.8
                when 'fragile' then 1.3
                else 1.0
                end
    
    (base_rate * distance_km * multiplier).round(2)
  end

  def active_shipments_count
    shipments.where(status: [:pending, :in_transit]).count
  end
end