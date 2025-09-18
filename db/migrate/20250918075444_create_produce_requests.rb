class CreateProduceRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :produce_requests do |t|
      t.references :market_profile, null: false, foreign_key: true
      t.references :produce_listing, null: false, foreign_key: true
      t.decimal :quantity
      t.decimal :price_offered
      t.text :message
      t.integer :status

      t.timestamps
    end
  end
end
