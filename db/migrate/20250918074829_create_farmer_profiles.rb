class CreateFarmerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :farmer_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :full_name
      t.string :farm_name
      t.json :farm_location
      t.text :produce_types
      t.text :livestock
      t.text :crops
      t.string :production_capacity
      t.text :certifications
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
