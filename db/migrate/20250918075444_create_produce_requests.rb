class CreateProduceRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :produce_requests do |t|
      t.references :market_profile, null: false, foreign_key: true
      t.references :produce_listing, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.decimal :price_offered, precision: 10, scale: 2
      t.text :message
      t.integer :status, default: 0
      t.datetime :expires_at
      t.timestamps
    end

    add_index :produce_requests, :status
    add_index :produce_requests, [:produce_listing_id, :status]
  end
end
