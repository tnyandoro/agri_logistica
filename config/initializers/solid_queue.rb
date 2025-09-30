if Rails.env.production?
    Rails.application.configure do
      config.solid_queue.connects_to = { database: { writing: :queue } }
    end
  end
  
  # Uncomment these only if you upgrade Solid Queue >= 1.3.0
  # SolidQueue.configure do |config|
  #   config.default_concurrency = 5
  #   config.silence_polling = true
  # end
  