# config/routes.rb
Rails.application.routes.draw do
  # Root
  root 'home#index'

  # Devise routes with custom registrations controller
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Custom registration routes for different user types
  devise_scope :user do
    get '/register/farmer', to: 'users/registrations#new', defaults: { user_role: 'farmer' }, as: :farmer_registration
    get '/register/trucker', to: 'users/registrations#new', defaults: { user_role: 'trucker' }, as: :trucker_registration
    get '/register/market', to: 'users/registrations#new', defaults: { user_role: 'market' }, as: :market_registration
    
    # Profile completion routes (if needed separately)
    get '/complete_profile', to: 'users/registrations#complete_profile', as: :complete_profile
    patch '/update_profile', to: 'users/registrations#update_profile', as: :update_profile
  end

  # Authenticated routes
  authenticate :user do
    # Dashboard
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    
    # Farmer routes
    resources :farmer_profiles, only: [:show, :edit, :update]
    resources :produce_listings do
      resources :produce_requests, except: [:index]
    end
    
    # Trucker routes
    resources :trucking_companies, only: [:show, :edit, :update]
    resources :shipments do
      resources :shipment_bids, except: [:index, :show]
    end
    
    # Market routes
    resources :market_profiles, only: [:show, :edit, :update]
    
    # Common routes
    resources :notifications, only: [:index, :show, :update]
    
    # Search and filtering
    get '/search', to: 'search#index', as: :search
    get '/browse/:category', to: 'browse#show', as: :browse_category
  end

  # Public routes
  get 'home/index'
  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'
  get 'how_it_works', to: 'pages#how_it_works'

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
  get 'up', to: 'rails/health#show', as: :rails_health_check
end