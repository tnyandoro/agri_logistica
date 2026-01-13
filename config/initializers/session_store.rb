Rails.application.config.session_store :cookie_store,
  key: "_my_app_session",
  same_site: :lax,   # :none if using HTTPS
  secure: false      # true in production with HTTPS
