class AddFieldsToMarketProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :market_profiles, :contact_person, :string
    add_column :market_profiles, :description, :text
    add_column :market_profiles, :purchase_volume, :string
    add_column :market_profiles, :delivery_preferences, :string
    add_column :market_profiles, :organic_certified, :boolean, default: false
    add_column :market_profiles, :gap_certified, :boolean, default: false
    add_column :market_profiles, :haccp_certified, :boolean, default: false
  end
end