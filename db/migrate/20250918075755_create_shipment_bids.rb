class CreateShipmentBids < ActiveRecord::Migration[8.0]
  def change
    create_table :shipment_bids do |t|
      t.references :shipment, null: false, foreign_key: true
      t.references :trucking_company, null: false, foreign_key: true
      t.decimal :bid_amount
      t.text :message
      t.integer :status

      t.timestamps
    end
  end
end
