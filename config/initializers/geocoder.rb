Geocoder.configure(
  # Geocoding service configuration
  lookup: :google,
  api_key: ENV['GOOGLE_MAPS_API_KEY'],
  use_https: true,
  
  # Caching configuration (using Rails cache)
  cache: Rails.cache,
  cache_prefix: 'geocoder:',
  
  # Request timeout
  timeout: 3,
  
  # Rate limiting
  always_raise: :all,
  
  # Units
  units: :km
)

# config/initializers/solid_queue.rb
# Solid Queue configuration for Rails 8
if Rails.env.production?
  Rails.application.configure do
    config.solid_queue.connects_to = { database: { writing: :queue } }
  end
end

# Configure job queues
# SolidQueue.configure do |config|
#   config.default_concurrency = 5
#   config.silence_polling = true
# end
