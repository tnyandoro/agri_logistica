class AddCapacityToTruckingCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :trucking_companies, :capacity, :integer
  end
end
