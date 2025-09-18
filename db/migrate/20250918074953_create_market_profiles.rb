class CreateMarketProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :market_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :market_name
      t.integer :market_type
      t.json :location
      t.text :preferred_produces
      t.string :demand_volume
      t.string :payment_terms
      t.string :operating_hours
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
