class Shipment < ApplicationRecord
  belongs_to :produce_listing
  belongs_to :produce_request
  belongs_to :trucking_company, optional: true
  has_many :shipment_bids, dependent: :destroy
  
  validates :origin_address, :destination_address, presence: true
  validates :tracking_number, uniqueness: true, allow_nil: true
  
  enum status: { 
    pending_bids: 0, 
    bid_accepted: 1, 
    pickup_scheduled: 2, 
    in_transit: 3, 
    delivered: 4, 
    cancelled: 5 
  }
  
  before_create :generate_tracking_number
  scope :available_for_bidding, -> { where(status: :pending_bids) }
  scope :active, -> { where(status: [:bid_accepted, :pickup_scheduled, :in_transit]) }

  def farmer
    produce_listing.farmer_profile.user
  end

  def market
    produce_request.market_profile.user
  end

  def accepted_bid
    shipment_bids.find_by(status: :accepted)
  end

  def lowest_bid
    shipment_bids.where(status: :pending).order(:bid_amount).first
  end

  private

  def generate_tracking_number
    self.tracking_number = "AG#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end
end