class Shipment < ApplicationRecord
  # Associations
  belongs_to :produce_listing
  belongs_to :produce_request
  belongs_to :trucking_company, optional: true
  has_many :shipment_bids, dependent: :destroy
  
  # Delegations for easier access
  delegate :farmer_profile, to: :produce_listing
  delegate :market_profile, to: :produce_request
  
  # Validations
  validates :origin_address, :destination_address, presence: true
  validates :pickup_date, :delivery_date, presence: true
  validates :distance_km, numericality: { greater_than: 0 }, allow_nil: true
  validates :agreed_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :delivery_after_pickup
  
  # Enum for status
  enum :status, { 
    pending: 0,           # Waiting for bids
    bidding_open: 1,      # Accepting bids from truckers
    bid_accepted: 2,      # A bid has been accepted
    in_transit: 3,        # Shipment is on the way
    delivered: 4,         # Successfully delivered
    cancelled: 5,         # Shipment cancelled
    failed: 6             # Delivery failed
  }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: [:pending, :bidding_open, :bid_accepted, :in_transit]) }
  scope :completed, -> { where(status: [:delivered, :cancelled, :failed]) }
  scope :needs_trucker, -> { where(status: [:pending, :bidding_open], trucking_company_id: nil) }
  scope :by_pickup_date, -> { order(:pickup_date) }
  scope :available_for_bidding, -> { 
    where(status: [:pending, :bidding_open])
    .where(trucking_company_id: nil)
    .where('pickup_date >= ?', Date.today)
    .order(created_at: :desc) 
  }
  
  # Callbacks
  before_validation :calculate_distance, if: :locations_changed?
  before_create :generate_tracking_number
  after_create :notify_truckers
  after_update :notify_status_change, if: :saved_change_to_status?
  
  # Instance methods
  def farmer
    farmer_profile.user
  end
  
  def market
    market_profile.user
  end
  
  def trucker
    trucking_company&.user
  end
  
  def accepted_bid
    shipment_bids.find_by(status: :accepted)
  end
  
  def pending_bids_count
    shipment_bids.pending.count
  end
  
  def lowest_bid
    shipment_bids.pending.minimum(:bid_amount)
  end
  
  def highest_bid
    shipment_bids.pending.maximum(:bid_amount)
  end
  
  def average_bid
    shipment_bids.pending.average(:bid_amount)&.round(2)
  end
  
  def duration_days
    return 0 unless pickup_date && delivery_date
    ((delivery_date.to_date - pickup_date.to_date).to_i).abs
  end
  
  def cost_per_km
    return 0 unless agreed_price && distance_km && distance_km > 0
    (agreed_price / distance_km).round(2)
  end
  
  def can_accept_bids?
    pending? || bidding_open?
  end
  
  def can_start_transit?
    bid_accepted? && trucking_company.present?
  end
  
  def can_complete?
    in_transit?
  end
  
  def mark_as_in_transit!
    return false unless can_start_transit?
    
    update(status: :in_transit)
    notify_parties("Shipment is now in transit")
  end
  
  def mark_as_delivered!
    return false unless can_complete?
    
    transaction do
      update!(status: :delivered)
      
      # Mark the produce request as completed
      produce_request.update(status: :completed)
      
      # Mark the produce listing as sold if this was the full quantity
      if produce_request.quantity >= produce_listing.quantity
        produce_listing.mark_as_sold!
      end
    end
    
    notify_parties("Shipment has been delivered successfully")
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end
  
  def mark_as_cancelled!(reason = nil)
    update(status: :cancelled)
    
    # Reject all pending bids
    shipment_bids.pending.update_all(status: :rejected)
    
    notify_parties("Shipment has been cancelled")
  end
  
  def accept_bid!(bid)
    return false unless can_accept_bids?
    return false unless bid.shipment == self
    
    transaction do
      # Accept the selected bid
      bid.update!(status: :accepted)
      
      # Reject all other bids
      shipment_bids.where.not(id: bid.id).pending.update_all(status: :rejected)
      
      # Assign the trucking company and update status
      update!(
        trucking_company: bid.trucking_company,
        agreed_price: bid.bid_amount,
        status: :bid_accepted
      )
    end
    
    notify_parties("Bid accepted for shipment")
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end
  
  def tracking_info
    {
      status: status,
      tracking_number: tracking_number,
      origin: origin_address,
      destination: destination_address,
      pickup_date: pickup_date,
      delivery_date: delivery_date,
      distance_km: distance_km,
      trucker: trucker&.email
    }
  end
  
  private
  
  def delivery_after_pickup
    return unless pickup_date && delivery_date
    
    if delivery_date < pickup_date
      errors.add(:delivery_date, "must be after pickup date")
    end
  end
  
  def locations_changed?
    origin_address_changed? || destination_address_changed? ||
    pickup_location_changed? || delivery_location_changed?
  end
  
  def calculate_distance
    return unless pickup_location.present? && delivery_location.present?
    
    # Extract coordinates from JSON locations
    pickup_coords = [
      pickup_location['lat'] || pickup_location[:lat],
      pickup_location['lng'] || pickup_location[:lng]
    ]
    
    delivery_coords = [
      delivery_location['lat'] || delivery_location[:lat],
      delivery_location['lng'] || delivery_location[:lng]
    ]
    
    if pickup_coords.all?(&:present?) && delivery_coords.all?(&:present?)
      # Calculate distance using Geocoder
      self.distance_km = Geocoder::Calculations.distance_between(
        pickup_coords,
        delivery_coords,
        units: :km
      ).round(2)
    end
  end
  
  def generate_tracking_number
    self.tracking_number ||= "SHIP#{Time.current.to_i}#{rand(1000..9999)}"
  end
  
  def notify_truckers
    # Notify all trucking companies about new shipment available for bidding
    TruckingCompany.find_each do |company|
      Notification.create!(
        user: company.user,
        title: "New Shipment Available",
        message: "A new shipment from #{origin_address} to #{destination_address} is available for bidding.",
        notification_type: :shipment
      )
    end
  end
  
  def notify_status_change
    notify_parties("Shipment status changed to #{status.humanize}")
  end
  
  def notify_parties(message)
    [farmer, market, trucker].compact.each do |user|
      Notification.create!(
        user: user,
        title: "Shipment Update",
        message: message,
        notification_type: :shipment
      )
    end
  end
end