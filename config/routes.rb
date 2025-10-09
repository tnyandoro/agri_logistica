Rails.application.routes.draw do
  # Devise routes with custom controllers for API authentication
  devise_for :users, 
             controllers: {
               registrations: 'users/registrations',
               sessions: 'users/sessions'
             },
             defaults: { format: :json },
             skip: [:passwords, :confirmations, :unlocks]

  # Root endpoint - API information
  root to: 'api/v1/home#index'  # <- updated to namespaced controller

  # API routes
  namespace :api do
    namespace :v1 do
      # HomeController (API info) is already set as root
      # Dashboard
      get 'dashboard', to: 'dashboard#index'
      
      # Public endpoints (no authentication required)
      resources :produce_listings, only: [:index, :show]
      resources :markets, only: [:index, :show]
      resources :truckers, only: [:index, :show]
      get 'search', to: 'search#index'
      
      # Authenticated endpoints
      # Farmer routes
      resources :farmer_profiles, only: [:show, :update] do
        member do
          get 'dashboard', to: 'farmer_profiles#dashboard'
        end
      end
      
      resources :produce_listings, only: [:create, :update, :destroy] do
        resources :produce_requests, except: [:index]
      end
      
      # Trucker routes
      resources :trucking_companies, only: [:show, :update] do
        member do
          get 'dashboard', to: 'trucking_companies#dashboard'
        end
      end
      
      resources :shipments do
        resources :shipment_bids, except: [:index, :show]
      end
      
      # Market routes
      resources :market_profiles, only: [:show, :update] do
        member do
          get 'dashboard', to: 'market_profiles#dashboard'
        end
      end
      
      # Common routes
      resources :notifications, only: [:index, :show, :update] do
        collection do
          patch 'mark_all_read'
        end
      end
      
      # User profile management
      resource :profile, only: [:show, :update] do
        patch 'complete', to: 'profiles#complete'
      end
      
      # Browse and filter
      get 'browse/:category', to: 'browse#show'
    end
  end

  # Health check
  get 'up', to: 'rails/health#show', as: :rails_health_check
  
  # API documentation endpoint (optional)
  get 'api/docs', to: 'api/documentation#index'
end
