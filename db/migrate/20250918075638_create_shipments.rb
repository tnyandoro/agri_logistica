class CreateShipments < ActiveRecord::Migration[8.0]
  def change
    create_table :shipments do |t|
      t.references :produce_listing, null: false, foreign_key: true
      t.references :trucking_company, null: true, foreign_key: true
      t.references :produce_request, null: false, foreign_key: true
      t.string :origin_address, null: false
      t.string :destination_address, null: false
      t.datetime :pickup_date
      t.datetime :delivery_date
      t.integer :status, default: 0
      t.string :tracking_number
      t.decimal :distance_km, precision: 8, scale: 2
      t.decimal :agreed_price, precision: 10, scale: 2
      t.json :pickup_location, default: {}
      t.json :delivery_location, default: {}
      t.timestamps
    end

    add_index :shipments, :status
    add_index :shipments, :tracking_number, unique: true
    add_index :shipments, :pickup_date
  end
end
