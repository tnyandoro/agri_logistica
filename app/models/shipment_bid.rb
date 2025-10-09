  class ShipmentBid < ApplicationRecord
    belongs_to :shipment
    belongs_to :trucking_company
    
    validates :bid_amount, presence: true, numericality: { greater_than: 0 }
    validates :pickup_time, :estimated_delivery, presence: true
    validate :pickup_before_delivery
    
    enum :status, { pending: 0, accepted: 1, rejected: 2, cancelled: 3 }  # FIXED: Added colon
    
    scope :recent, -> { order(created_at: :desc) }
    scope :by_amount, -> { order(:bid_amount) }

    def trucker
      trucking_company.user
    end

    def delivery_duration_hours
      return 0 unless pickup_time && estimated_delivery
      ((estimated_delivery - pickup_time) / 1.hour).round(1)
    end

    private

    def pickup_before_delivery
      return unless pickup_time && estimated_delivery
      
      errors.add(:estimated_delivery, 'must be after pickup time') if estimated_delivery <= pickup_time
    end
  end