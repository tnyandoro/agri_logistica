Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173', 'http://localhost:5174', 'http://127.0.0.1:5173', 'http://127.0.0.1:5174'

    resource '*',
             headers: :any,
             expose: ['Authorization'],
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
  end
end
