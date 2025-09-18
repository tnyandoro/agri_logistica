class ProduceListing < ApplicationRecord
  belongs_to :farmer_profile
  has_many :produce_requests, dependent: :destroy
  has_many :shipments, dependent: :destroy
  
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :produce_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true
  validates :price_per_unit, presence: true, numericality: { greater_than: 0 }
  validates :available_from, :available_until, presence: true
  validate :available_until_after_available_from
  
  enum status: { available: 0, reserved: 1, sold: 2, expired: 3 }
  
  scope :available_now, -> { where(status: :available).where('available_from <= ? AND available_until >= ?', Date.current, Date.current) }
  scope :by_produce_type, ->(type) { where(produce_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :organic_only, -> { where(organic: true) }

  def farmer
    farmer_profile.user
  end
  
  def farm_location
    farmer_profile.farm_location
  end

  def expired?
    available_until < Date.current
  end

  def available_quantity
    quantity - reserved_quantity
  end

  def reserved_quantity
    produce_requests.where(status: :accepted).sum(:quantity)
  end

  def total_value
    quantity * price_per_unit
  end

  private

  def available_until_after_available_from
    return unless available_from && available_until
    
    errors.add(:available_until, 'must be after available from date') if available_until < available_from
  end
end