class AddBusinessNameToMarketProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :market_profiles, :business_name, :string
    # Optionally copy market_name to business_name for existing records
    # reversible do |dir|
    #   dir.up do
    #     execute "UPDATE market_profiles SET business_name = market_name"
    #   end
    # end
  end
end