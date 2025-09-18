class Shipment < ApplicationRecord
  belongs_to :produce_listing
  belongs_to :trucking_company
end
