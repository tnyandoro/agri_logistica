namespace :db do
    desc "Generate sample data for development"
    task sample_data: :environment do
      puts "Creating sample data..."
  
      # Create sample users
      farmer_user = User.create!(
        email: 'farmer@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        phone: '+1234567890',
        user_role: 'farmer',
        verified: true
      )
  
      trucker_user = User.create!(
        email: 'trucker@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        phone: '+1234567891',
        user_role: 'trucker',
        verified: true
      )
  
      market_user = User.create!(
        email: 'market@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        phone: '+1234567892',
        user_role: 'market',
        verified: true
      )
  
      # Update farmer profile
      farmer_user.farmer_profile.update!(
        full_name: 'John Farmer',
        farm_name: 'Sunny Acres Farm',
        farm_location: {
          'address' => '123 Farm Road, Rural County, State 12345',
          'lat' => 40.7128,
          'lng' => -74.0060
        },
        produce_types: ['Crops', 'Organic'],
        crops: ['Tomatoes', 'Corn', 'Wheat'],
        production_capacity: '500 tons/year',
        latitude: 40.7128,
        longitude: -74.0060
      )
  
      # Update trucker profile
      trucker_user.trucking_company.update!(
        company_name: 'Fast Haul Logistics',
        vehicle_types: ['Refrigerated Truck', 'Flatbed'],
        registration_numbers: ['TRUCK001', 'TRUCK002'],
        routes: [
          { 'from' => 'Rural County', 'to' => 'City Market', 'distance' => '150km' }
        ],
        rates: [
          { 'type' => 'per_km', 'rate' => 2.5, 'currency' => 'USD' }
        ],
        fleet_size: 5,
        contact_person: 'Mike Driver'
      )
  
      # Update market profile
      market_user.market_profile.update!(
        market_name: 'Central Wholesale Market',
        market_type: 'wholesale',
        location: {
          'address' => '456 Market Street, Big City, State 54321',
          'lat' => 40.7589,
          'lng' => -73.9851
        },
        preferred_produces: ['Crops', 'Organic', 'Vegetables'],
        demand_volume: '1000kg/month',
        payment_terms: 'Net 30 days',
        operating_hours: 'Mon-Fri 6AM-6PM',
        latitude: 40.7589,
        longitude: -73.9851
      )
  
      # Create sample produce listings
      3.times do |i|
        ProduceListing.create!(
          farmer_profile: farmer_user.farmer_profile,
          title: "Fresh #{['Tomatoes', 'Corn', 'Wheat'][i]}",
          description: "High quality #{['tomatoes', 'corn', 'wheat'][i]} from our organic farm",
          produce_type: ['Vegetables', 'Grains', 'Grains'][i],
          quantity: [500, 1000, 2000][i],
          unit: 'kg',
          price_per_unit: [5.50, 3.25, 2.75][i],
          available_from: Date.current,
          available_until: 1.month.from_now,
          organic: [true, false, false][i]
        )
      end
  
      puts "Sample data created successfully!"
      puts "Login credentials:"
      puts "Farmer: farmer@example.com / password123"
      puts "Trucker: trucker@example.com / password123"
      puts "Market: market@example.com / password123"
    end
  end