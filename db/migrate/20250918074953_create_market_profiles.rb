class CreateMarketProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :market_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :market_name, null: false
      t.integer :market_type, null: false, default: 0
      t.json :location, null: false
      t.text :preferred_produces, array: true, default: []
      t.string :demand_volume
      t.string :payment_terms
      t.string :operating_hours
      t.decimal :latitude, precision: 15, scale: 10
      t.decimal :longitude, precision: 15, scale: 10
      t.timestamps
    end

    add_index :market_profiles, [:latitude, :longitude]
    add_index :market_profiles, :market_type
    add_index :market_profiles, :preferred_produces, using: 'gin'
  end
end
