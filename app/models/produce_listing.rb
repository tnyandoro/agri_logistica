class ProduceListing < ApplicationRecord
  # Associations
  belongs_to :farmer_profile
  has_many :produce_requests, dependent: :destroy
  has_many :shipments, dependent: :destroy 
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :produce_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true
  validates :price_per_unit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :available_from, presence: true
  validates :available_until, presence: true
  validate :available_until_after_available_from

  # Enum for status
  enum :status, { available: 0, reserved: 1, sold: 2, expired: 3 }

  # Scopes
  scope :available_now, -> { where(status: :available).where('available_from <= ? AND available_until >= ?', Date.current, Date.current) }
  scope :by_produce_type, ->(type) { where(produce_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :expiring_soon, -> { where(status: :available).where('available_until <= ?', 7.days.from_now) }

  # Callbacks
  before_save :calculate_total_value
  after_create :notify_interested_markets

  # Instance methods
  def days_until_expiry
    return 0 if available_until.nil? || available_until < Date.current
    (available_until - Date.current).to_i
  end

  def expired?
    available_until < Date.current
  end

  def mark_as_sold!
    update(status: :sold)
  end

  def mark_as_reserved!
    update(status: :reserved)
  end

  def mark_as_available!
    update(status: :available)
  end

  def total_value
    quantity * price_per_unit
  end

  private

  def available_until_after_available_from
    return if available_until.blank? || available_from.blank?

    if available_until < available_from
      errors.add(:available_until, "must be after available from date")
    end
  end

  def calculate_total_value
    self.total_value = quantity * price_per_unit if quantity && price_per_unit
  end

  def notify_interested_markets
    # Find markets interested in this produce type
    interested_markets = MarketProfile.all.select do |market|
      market.preferred_produces.include?(produce_type)
    end
    
    interested_markets.each do |market|
      Notification.create!(
        user: market.user,
        title: "New Listing Available",
        message: "New #{produce_type} listing from #{farmer_profile.farm_name}",
        notification_type: :match,
        data: { listing_id: id }
      )
    end
  end
end