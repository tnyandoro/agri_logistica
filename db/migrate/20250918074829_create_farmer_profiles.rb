class CreateFarmerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :farmer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :full_name, null: false
      t.string :farm_name, null: false
      t.json :farm_location, null: false
      t.text :produce_types, array: true, default: []
      t.text :livestock, array: true, default: []
      t.text :crops, array: true, default: []
      t.string :production_capacity
      t.text :certifications, array: true, default: []
      t.decimal :latitude, precision: 15, scale: 10
      t.decimal :longitude, precision: 15, scale: 10
      t.timestamps
    end

    add_index :farmer_profiles, [:latitude, :longitude]
    add_index :farmer_profiles, :produce_types, using: 'gin'
  end
end
