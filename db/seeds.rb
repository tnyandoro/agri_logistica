# db/seeds.rb
puts "🌱 Seeding database..."

require 'faker'

# Clear old data (in correct order due to foreign key constraints)
Notification.destroy_all
ShipmentBid.destroy_all
Shipment.destroy_all
ProduceRequest.destroy_all
ProduceListing.destroy_all
FarmerProfile.destroy_all
MarketProfile.destroy_all
TruckingCompany.destroy_all
User.destroy_all

puts "🗑️  Cleared existing data"

# -----------------------------
# Create a Farmer User
# -----------------------------
farmer_user = User.create!(
  email: "farmer@example.com",
  password: "password123",
  password_confirmation: "password123",
  phone_number: "+27123456789",
  user_role: :farmer,
  verified: true
)

# Ensure profile exists (callback should create it, but let's be safe)
farmer_profile = farmer_user.farmer_profile || farmer_user.create_farmer_profile!(
  full_name: "Temp",
  farm_name: "Temp",
  farm_location: {}
)

# Now update the profile with real data
farmer_profile.update!(
  full_name: "Liam Becker",
  farm_name: "Water Valley Farm",
  farm_location: { 
    address: "22 Kempton Road, Johannesburg, South Africa",
    lat: -26.2041,
    lng: 28.0473
  },
  production_capacity: "150",
  produce_types: %w[Crops Poultry],
  crops: %w[Maize Wheat Sorghum],
  livestock: %w[Chicken],
  certifications: ["Organic Certified", "Local Supplier", "GAP Certified"],
  latitude: -26.2041,
  longitude: 28.0473
)

puts "👨‍🌾 Created Farmer: #{farmer_profile.full_name} (#{farmer_profile.farm_name})"

# -----------------------------
# Create sample produce listings
# -----------------------------
produce_types = [
  { type: 'Maize', unit: 'ton', price_range: 3000..5000 },
  { type: 'Wheat', unit: 'ton', price_range: 4000..6000 },
  { type: 'Chicken', unit: 'kg', price_range: 45..75 },
  { type: 'Eggs', unit: 'dozen', price_range: 30..50 },
  { type: 'Sorghum', unit: 'ton', price_range: 2500..4500 }
]

produce_types.each do |produce|
  ProduceListing.create!(
    farmer_profile: farmer_profile,
    title: "Fresh #{produce[:type]} Available",
    description: "High-quality #{produce[:type].downcase} from #{farmer_profile.farm_name}. " +
                 "Organically grown and certified. Available for immediate delivery.",
    produce_type: produce[:type],
    quantity: rand(50..500),
    unit: produce[:unit],
    price_per_unit: rand(produce[:price_range]),
    available_from: Date.today,
    available_until: Date.today + rand(14..45).days,
    status: :available,
    organic: [true, false].sample,
    quality_specs: {
      grade: ['A', 'B', 'Premium'].sample,
      moisture_content: "#{rand(10..14)}%",
      packaging: ['Bulk', '25kg bags', '50kg bags'].sample
    }
  )
end

puts "📦 Created #{ProduceListing.count} produce listings"

# -----------------------------
# Create additional farmers
# -----------------------------
3.times do |i|
  user = User.create!(
    email: "farmer#{i + 2}@example.com",
    password: "password123",
    password_confirmation: "password123",
    phone_number: "+2712345678#{i + 10}",
    user_role: :farmer,
    verified: true
  )

  # Ensure profile exists
  profile = user.farmer_profile || user.create_farmer_profile!(
    full_name: "Temp",
    farm_name: "Temp",
    farm_location: {}
  )

  farm_names = ["Green Valley Farm", "Sunrise Agriculture", "Fresh Harvest Co."]
  locations = [
    { address: "Pretoria, Gauteng", lat: -25.7479, lng: 28.2293 },
    { address: "Durban, KwaZulu-Natal", lat: -29.8587, lng: 31.0218 },
    { address: "Cape Town, Western Cape", lat: -33.9249, lng: 18.4241 }
  ]

  profile.update!(
    full_name: Faker::Name.name,
    farm_name: farm_names[i],
    farm_location: locations[i],
    production_capacity: rand(50..300).to_s,
    produce_types: ['Crops', 'Vegetables', 'Fruits'].sample(2),
    crops: ['Maize', 'Wheat', 'Sorghum', 'Beans'].sample(2),
    livestock: [],
    certifications: ['Organic Certified'].sample(1),
    latitude: locations[i][:lat],
    longitude: locations[i][:lng]
  )
end

puts "👨‍🌾 Created #{FarmerProfile.count} total farmers"

# -----------------------------
# Create a Market User
# -----------------------------
market_user = User.create!(
  email: "market@example.com",
  password: "password123",
  password_confirmation: "password123",
  phone_number: "+27987654321",
  user_role: :market,
  verified: true
)

# Ensure profile exists
market_profile = market_user.market_profile || market_user.create_market_profile!(
  market_name: "Temp",
  location: {}
)

market_profile.update!(
  market_name: "Johannesburg Fresh Market",
  market_type: :wholesale,
  location: { 
    address: "1 Market Street, Johannesburg",
    lat: -26.2041,
    lng: 28.0473
  },
  preferred_produces: %w[Maize Wheat Chicken Vegetables],
  demand_volume: "500-1000",
  payment_terms: "Net 30 days",
  operating_hours: "Mon-Fri 6AM-6PM, Sat 6AM-2PM",
  contact_person: "John Market Manager",
  description: "Leading wholesale market in Johannesburg. " +
               "We buy fresh produce from local farmers for distribution to retailers.",
  purchase_volume: "5-10",
  delivery_preferences: "Delivery to our warehouse",
  organic_certified: true,
  gap_certified: true,
  haccp_certified: false,
  latitude: -26.2041,
  longitude: 28.0473
)

puts "🏪 Created Market: #{market_profile.market_name}"

# Create more markets
2.times do |i|
  user = User.create!(
    email: "market#{i + 2}@example.com",
    password: "password123",
    password_confirmation: "password123",
    phone_number: "+2798765432#{i + 10}",
    user_role: :market,
    verified: true
  )

  # Ensure profile exists
  profile = user.market_profile || user.create_market_profile!(
    market_name: "Temp",
    location: {}
  )

  market_names = ["Cape Town Wholesale Hub", "Durban Fresh Market"]
  locations = [
    { address: "Cape Town, Western Cape", lat: -33.9249, lng: 18.4241 },
    { address: "Durban, KwaZulu-Natal", lat: -29.8587, lng: 31.0218 }
  ]

  profile.update!(
    market_name: market_names[i],
    market_type: :wholesale,  # ✅ FIXED: Only use :wholesale
    location: locations[i],
    preferred_produces: ['Maize', 'Wheat', 'Vegetables', 'Fruits'].sample(3),
    demand_volume: rand(200..800).to_s,
    payment_terms: ["Net 30", "Net 15", "Cash on delivery"].sample,
    operating_hours: "Mon-Sat 6AM-6PM",
    contact_person: Faker::Name.name,
    description: "Quality produce buyer",
    latitude: locations[i][:lat],
    longitude: locations[i][:lng]
  )
end

puts "🏪 Created #{MarketProfile.count} total markets"

# -----------------------------
# Create Trucking Company Users
# -----------------------------
trucking_user = User.create!(
  email: "trucking@example.com",
  password: "password123",
  password_confirmation: "password123",
  phone_number: "+27111222333",
  user_role: :trucker,
  verified: true
)

# Ensure profile exists
trucking_company = trucking_user.trucking_company || trucking_user.create_trucking_company!(
  company_name: "Temp"
)

trucking_company.update!(
  company_name: "Fast Freight Logistics",
  vehicle_types: %w[Refrigerated Box Flatbed],
  registration_numbers: ["ABC123GP", "DEF456GP", "GHI789GP"],
  routes: [
    { from: "Johannesburg", to: "Pretoria", distance: 50 },
    { from: "Johannesburg", to: "Durban", distance: 570 },
    { from: "Johannesburg", to: "Cape Town", distance: 1400 }
  ],
  rates: [
    { type: "Refrigerated", rate: 15.5, currency: "ZAR" },
    { type: "Box", rate: 12.0, currency: "ZAR" },
    { type: "Flatbed", rate: 10.0, currency: "ZAR" }
  ],
  fleet_size: 15,
  contact_person: "Mike Transport",
  insurance_details: "Fully insured - Santam Policy #AGRI-12345-2024"
)

puts "🚚 Created Trucking Company: #{trucking_company.company_name}"

# Create more trucking companies
2.times do |i|
  user = User.create!(
    email: "trucking#{i + 2}@example.com",
    password: "password123",
    password_confirmation: "password123",
    phone_number: "+2711122233#{i + 10}",
    user_role: :trucker,
    verified: true
  )

  # Ensure profile exists
  profile = user.trucking_company || user.create_trucking_company!(
    company_name: "Temp"
  )

  company_names = ["Cape Logistics Ltd", "Swift Transport SA"]
  
  profile.update!(
    company_name: company_names[i],
    vehicle_types: ['Refrigerated', 'Box', 'Flatbed'].sample(2),
    registration_numbers: ["XYZ#{rand(100..999)}GP"],
    fleet_size: rand(5..20),
    contact_person: Faker::Name.name,
    insurance_details: "Fully insured"
  )
end

puts "🚚 Created #{TruckingCompany.count} total trucking companies"

# -----------------------------
# Create Sample Produce Requests
# -----------------------------
first_listing = ProduceListing.first
if first_listing && market_profile
  ProduceRequest.create!(
    market_profile: market_profile,
    produce_listing: first_listing,
    quantity: rand(50..200),
    price_offered: first_listing.price_per_unit * 0.95,
    message: "Interested in purchasing for our wholesale market. Can you deliver to Johannesburg?",
    status: :pending,
    expires_at: 7.days.from_now
  )
  
  puts "📋 Created sample produce request"
end

# -----------------------------
# Create Notifications
# -----------------------------
Notification.create!(
  user: market_user,
  title: "New Listing Alert",
  message: "New #{ProduceListing.first&.produce_type} listing available from #{farmer_profile.farm_name}",
  notification_type: :match,
  data: { listing_id: ProduceListing.first&.id }
)

Notification.create!(
  user: farmer_user,
  title: "New Purchase Request",
  message: "#{market_profile.market_name} has requested a quote for your produce",
  notification_type: :match,  # ✅ FIXED: Changed from :request to :match (valid enum value)
  data: { market_id: market_profile.id }
)

puts "🔔 Created #{Notification.count} notifications"

# -----------------------------
# Summary
# -----------------------------
puts "\n✅ Seeding completed successfully!"
puts "=" * 50
puts "Users: #{User.count}"
puts "  - Farmers: #{User.user_role_farmer.count}"
puts "  - Markets: #{User.user_role_market.count}"
puts "  - Trucking Companies: #{User.user_role_trucker.count}"
puts "Farmer Profiles: #{FarmerProfile.count}"
puts "Market Profiles: #{MarketProfile.count}"
puts "Trucking Companies: #{TruckingCompany.count}"
puts "Produce Listings: #{ProduceListing.count}"
puts "Produce Requests: #{ProduceRequest.count}"
puts "Notifications: #{Notification.count}"
puts "=" * 50
puts "\n📧 Login Credentials:"
puts "Farmer: farmer@example.com / password123"
puts "Market: market@example.com / password123"
puts "Trucker: trucking@example.com / password123"