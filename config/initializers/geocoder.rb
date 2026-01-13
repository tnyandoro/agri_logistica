Geocoder.configure(
  lookup: :nominatim,
  use_https: true,
  http_headers: { "User-Agent" => "AgriculturalLogistics (contact: support@your-domain.example)" },
  cache: Rails.cache,
  cache_prefix: 'geocoder:',
  timeout: 5,
  units: :km
)