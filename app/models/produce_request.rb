class ProduceRequest < ApplicationRecord
  belongs_to :market_profile
  belongs_to :produce_listing
  has_one :shipment, dependent: :destroy
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_offered, numericality: { greater_than: 0 }, allow_nil: true
  
  enum :status, { pending: 0, accepted: 1, rejected: 2, cancelled: 3, completed: 4 }  # FIXED
  
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: [:pending, :accepted]) }

  def market
    market_profile.user
  end

  def farmer
    produce_listing.farmer_profile.user
  end

  def total_offered_amount
    return 0 unless price_offered && quantity
    quantity * price_offered
  end

  def listing_total_amount
    return 0 unless quantity
    quantity * produce_listing.price_per_unit
  end
end