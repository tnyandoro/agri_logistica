Geocoder.configure(
  # Use free Nominatim instead of Google
  lookup: :nominatim,
  use_https: true,
  
  # Required header for Nominatim
  http_headers: {
    "User-Agent" => "AgriculturalLogistics"
  },
  
  # Caching configuration (using Rails cache)
  cache: Rails.cache,
  cache_prefix: 'geocoder:',
  
  # Request timeout
  timeout: 5,
  
  # Units
  units: :km
)