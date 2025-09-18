class CreateTruckingCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :trucking_companies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.text :vehicle_types
      t.text :registration_numbers
      t.json :routes
      t.json :rates
      t.integer :fleet_size
      t.text :insurance_details
      t.string :contact_person

      t.timestamps
    end
  end
end
