# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_20_100807) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "farmer_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "full_name", null: false
    t.string "farm_name", null: false
    t.json "farm_location", null: false
    t.text "produce_types", default: [], array: true
    t.text "livestock", default: [], array: true
    t.text "crops", default: [], array: true
    t.string "production_capacity"
    t.text "certifications", default: [], array: true
    t.decimal "latitude", precision: 15, scale: 10
    t.decimal "longitude", precision: 15, scale: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_farmer_profiles_on_latitude_and_longitude"
    t.index ["produce_types"], name: "index_farmer_profiles_on_produce_types", using: :gin
    t.index ["user_id"], name: "index_farmer_profiles_on_user_id", unique: true
  end

  create_table "market_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "market_name", null: false
    t.integer "market_type", default: 0, null: false
    t.json "location", null: false
    t.text "preferred_produces", default: [], array: true
    t.string "demand_volume"
    t.string "payment_terms"
    t.string "operating_hours"
    t.decimal "latitude", precision: 15, scale: 10
    t.decimal "longitude", precision: 15, scale: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contact_person"
    t.text "description"
    t.string "purchase_volume"
    t.string "delivery_preferences"
    t.boolean "organic_certified", default: false
    t.boolean "gap_certified", default: false
    t.boolean "haccp_certified", default: false
    t.string "additional_requirements"
    t.index ["latitude", "longitude"], name: "index_market_profiles_on_latitude_and_longitude"
    t.index ["market_type"], name: "index_market_profiles_on_market_type"
    t.index ["preferred_produces"], name: "index_market_profiles_on_preferred_produces", using: :gin
    t.index ["user_id"], name: "index_market_profiles_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.integer "notification_type", default: 0, null: false
    t.datetime "read_at"
    t.json "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "produce_listings", force: :cascade do |t|
    t.bigint "farmer_profile_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "produce_type", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "unit", default: "kg", null: false
    t.decimal "price_per_unit", precision: 10, scale: 2
    t.date "available_from"
    t.date "available_until"
    t.integer "status", default: 0
    t.json "quality_specs", default: {}
    t.boolean "organic", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_value"
    t.index ["available_from", "available_until"], name: "index_produce_listings_on_available_from_and_available_until"
    t.index ["farmer_profile_id"], name: "index_produce_listings_on_farmer_profile_id"
    t.index ["organic"], name: "index_produce_listings_on_organic"
    t.index ["produce_type"], name: "index_produce_listings_on_produce_type"
    t.index ["status"], name: "index_produce_listings_on_status"
  end

  create_table "produce_requests", force: :cascade do |t|
    t.bigint "market_profile_id", null: false
    t.bigint "produce_listing_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "price_offered", precision: 10, scale: 2
    t.text "message"
    t.integer "status", default: 0
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_profile_id"], name: "index_produce_requests_on_market_profile_id"
    t.index ["produce_listing_id", "status"], name: "index_produce_requests_on_produce_listing_id_and_status"
    t.index ["produce_listing_id"], name: "index_produce_requests_on_produce_listing_id"
    t.index ["status"], name: "index_produce_requests_on_status"
  end

  create_table "shipment_bids", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.bigint "trucking_company_id", null: false
    t.decimal "bid_amount", precision: 10, scale: 2, null: false
    t.text "message"
    t.integer "status", default: 0
    t.datetime "pickup_time"
    t.datetime "estimated_delivery"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipment_id", "status"], name: "index_shipment_bids_on_shipment_id_and_status"
    t.index ["shipment_id"], name: "index_shipment_bids_on_shipment_id"
    t.index ["status"], name: "index_shipment_bids_on_status"
    t.index ["trucking_company_id"], name: "index_shipment_bids_on_trucking_company_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.bigint "produce_listing_id", null: false
    t.bigint "trucking_company_id"
    t.bigint "produce_request_id", null: false
    t.string "origin_address", null: false
    t.string "destination_address", null: false
    t.datetime "pickup_date"
    t.datetime "delivery_date"
    t.integer "status", default: 0
    t.string "tracking_number"
    t.decimal "distance_km", precision: 8, scale: 2
    t.decimal "agreed_price", precision: 10, scale: 2
    t.json "pickup_location", default: {}
    t.json "delivery_location", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pickup_date"], name: "index_shipments_on_pickup_date"
    t.index ["produce_listing_id"], name: "index_shipments_on_produce_listing_id"
    t.index ["produce_request_id"], name: "index_shipments_on_produce_request_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["tracking_number"], name: "index_shipments_on_tracking_number", unique: true
    t.index ["trucking_company_id"], name: "index_shipments_on_trucking_company_id"
  end

  create_table "trucking_companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "company_name", null: false
    t.text "vehicle_types", default: [], array: true
    t.text "registration_numbers", default: [], array: true
    t.json "routes", default: [], array: true
    t.json "rates", default: [], array: true
    t.integer "fleet_size"
    t.text "insurance_details"
    t.string "contact_person"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_trucking_companies_on_company_name"
    t.index ["user_id"], name: "index_trucking_companies_on_user_id", unique: true
    t.index ["vehicle_types"], name: "index_trucking_companies_on_vehicle_types", using: :gin
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_role", default: 0, null: false
    t.string "phone_number", null: false
    t.boolean "verified", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_role"], name: "index_users_on_user_role"
  end

  add_foreign_key "farmer_profiles", "users"
  add_foreign_key "market_profiles", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "produce_listings", "farmer_profiles"
  add_foreign_key "produce_requests", "market_profiles"
  add_foreign_key "produce_requests", "produce_listings"
  add_foreign_key "shipment_bids", "shipments"
  add_foreign_key "shipment_bids", "trucking_companies"
  add_foreign_key "shipments", "produce_listings"
  add_foreign_key "shipments", "produce_requests"
  add_foreign_key "shipments", "trucking_companies"
  add_foreign_key "trucking_companies", "users"
end
