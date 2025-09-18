class CreateTruckingCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :trucking_companies do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :company_name, null: false
      t.text :vehicle_types, array: true, default: []
      t.text :registration_numbers, array: true, default: []
      t.json :routes, array: true, default: []
      t.json :rates, array: true, default: []
      t.integer :fleet_size
      t.text :insurance_details
      t.string :contact_person
      t.timestamps
    end

    add_index :trucking_companies, :vehicle_types, using: 'gin'
    add_index :trucking_companies, :company_name
  end
end
