class AddTotalValueToProduceListings < ActiveRecord::Migration[8.0]
  def change
    add_column :produce_listings, :total_value, :decimal, precision: 12, scale: 2
  end
end