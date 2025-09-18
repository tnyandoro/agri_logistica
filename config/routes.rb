Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "produce_listings/index"
      get "produce_listings/show"
    end
  end
  get "shipments/index"
  get "shipments/show"
  get "shipments/new"
  get "shipments/create"
  get "shipments/edit"
  get "shipments/update"
  get "market_profiles/show"
  get "market_profiles/edit"
  get "market_profiles/update"
  get "trucking_companies/show"
  get "trucking_companies/edit"
  get "trucking_companies/update"
  get "farmer_profiles/show"
  get "farmer_profiles/edit"
  get "farmer_profiles/update"
  get "home/index"
  
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root 'home#index'
  
  # Role-based registration routes
  get '/register/:role', to: 'users/registrations#new', as: :role_registration, constraints: { role: /farmer|trucker|market/ }
  get '/complete_profile', to: 'users/registrations#complete_profile'
  patch '/update_profile', to: 'users/registrations#update_profile'
  
  # Dashboard
  get '/dashboard', to: 'dashboard#index'
  
  # Main resources
  resources :produce_listings do
    resources :produce_requests, except: [:index]
  end
  
  resources :shipments do
    resources :shipment_bids, except: [:index, :show]
  end
  
  resources :farmer_profiles, only: [:show, :edit, :update]
  resources :trucking_companies, only: [:show, :edit, :update]  
  resources :market_profiles, only: [:show, :edit, :update]
  
  resources :notifications, only: [:index, :show, :update]
  
  # Search and filtering
  get '/search', to: 'search#index'
  get '/browse/:category', to: 'browse#show', as: :browse_category
  
  # API routes for mobile/ajax
  namespace :api do
    namespace :v1 do
      resources :produce_listings, only: [:index, :show]
      resources :markets, only: [:index]
      resources :truckers, only: [:index]
      resources :search, only: [:index]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
