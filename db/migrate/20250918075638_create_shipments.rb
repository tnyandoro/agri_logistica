class CreateShipments < ActiveRecord::Migration[8.0]
  def change
    create_table :shipments do |t|
      t.references :produce_listing, null: false, foreign_key: true
      t.references :trucking_company, null: false, foreign_key: true
      t.string :origin_address
      t.string :destination_address
      t.datetime :pickup_date
      t.datetime :delivery_date
      t.integer :status
      t.string :tracking_number

      t.timestamps
    end
  end
end
