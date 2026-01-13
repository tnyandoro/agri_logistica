class AddSafeFieldsToMarketProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :market_profiles, :contact_person, :string unless column_exists?(:market_profiles, :contact_person)
    add_column :market_profiles, :description, :text unless column_exists?(:market_profiles, :description)
    add_column :market_profiles, :purchase_volume, :string unless column_exists?(:market_profiles, :purchase_volume)
    add_column :market_profiles, :delivery_preferences, :string unless column_exists?(:market_profiles, :delivery_preferences)
    add_column :market_profiles, :organic_certified, :boolean, default: false unless column_exists?(:market_profiles, :organic_certified)
    add_column :market_profiles, :gap_certified, :boolean, default: false unless column_exists?(:market_profiles, :gap_certified)
    add_column :market_profiles, :haccp_certified, :boolean, default: false unless column_exists?(:market_profiles, :haccp_certified)
    add_column :market_profiles, :demand_volume, :string unless column_exists?(:market_profiles, :demand_volume)
    add_column :market_profiles, :payment_terms, :string unless column_exists?(:market_profiles, :payment_terms)
    add_column :market_profiles, :operating_hours, :string unless column_exists?(:market_profiles, :operating_hours)
    add_column :market_profiles, :additional_requirements, :text unless column_exists?(:market_profiles, :additional_requirements)
  end
end
