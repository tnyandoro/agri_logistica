class CreateProduceListings < ActiveRecord::Migration[8.0]
  def change
    create_table :produce_listings do |t|
      t.references :farmer_profile, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :produce_type
      t.decimal :quantity
      t.string :unit
      t.decimal :price_per_unit
      t.date :available_from
      t.date :available_until
      t.integer :status
      t.json :quality_specs
      t.boolean :organic

      t.timestamps
    end
  end
end
