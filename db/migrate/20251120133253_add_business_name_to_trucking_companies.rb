class AddBusinessNameToTruckingCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :trucking_companies, :business_name, :string
    # Optionally copy company_name to business_name for existing records
    # reversible do |dir|
    #   dir.up do
    #     execute "UPDATE trucking_companies SET business_name = company_name"
    #   end
    # end
  end
end