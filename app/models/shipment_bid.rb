class ShipmentBid < ApplicationRecord
  belongs_to :shipment
  belongs_to :trucking_company
end
