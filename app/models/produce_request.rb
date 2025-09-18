class ProduceRequest < ApplicationRecord
  belongs_to :market_profile
  belongs_to :produce_listing
end
