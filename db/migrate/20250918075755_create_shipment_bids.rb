class CreateShipmentBids < ActiveRecord::Migration[8.0]
  def change
    create_table :shipment_bids do |t|
      t.references :shipment, null: false, foreign_key: true
      t.references :trucking_company, null: false, foreign_key: true
      t.decimal :bid_amount, precision: 10, scale: 2, null: false
      t.text :message
      t.integer :status, default: 0
      t.datetime :pickup_time
      t.datetime :estimated_delivery
      t.timestamps
    end

    add_index :shipment_bids, :status
    add_index :shipment_bids, [:shipment_id, :status]
  end
end
