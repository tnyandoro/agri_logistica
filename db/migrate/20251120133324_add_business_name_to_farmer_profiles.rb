class AddBusinessNameToFarmerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :farmer_profiles, :business_name, :string
    # Optionally copy farm_name to business_name for existing records
    # reversible do |dir|
    #   dir.up do
    #     execute "UPDATE farmer_profiles SET business_name = farm_name"
    #   end
    # end
  end
end