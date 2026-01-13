class AddLocationToTruckingCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :trucking_companies, :location, :string
  end
end
