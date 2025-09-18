class CreateProduceListings < ActiveRecord::Migration[8.0]
  def change
    create_table :produce_listings do |t|
      t.references :farmer_profile, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :produce_type, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, null: false, default: 'kg'
      t.decimal :price_per_unit, precision: 10, scale: 2
      t.date :available_from
      t.date :available_until
      t.integer :status, default: 0
      t.json :quality_specs, default: {}
      t.boolean :organic, default: false
      t.timestamps
    end

    add_index :produce_listings, :status
    add_index :produce_listings, :produce_type
    add_index :produce_listings, [:available_from, :available_until]
    add_index :produce_listings, :organic
  end
end
