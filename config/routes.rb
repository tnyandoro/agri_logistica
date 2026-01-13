Rails.application.routes.draw do
  # ============================================================
  # DEVISE – API-only, JSON-only auth
  # ============================================================
  devise_for :users,
             controllers: {
               registrations: 'users/registrations',
               sessions: 'users/sessions'
             },
             defaults: { format: :json },
             skip: [:passwords, :confirmations, :unlocks]

  # Root endpoint
  root to: 'api/v1/home#index'

  # ============================================================
  # API V1 – JSON defaults
  # ============================================================
  namespace :api do
    namespace :v1, defaults: { format: :json } do
      
      # -------------------------
      # Authentication (JWT)
      # -------------------------
      post   'login',  to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'
      post   'users',  to: 'registrations#create'

      # -------------------------
      # Dashboard & Portal
      # -------------------------
      get 'dashboard', to: 'dashboard#index'
      get 'portal',    to: 'portal#index'

      # -------------------------
      # Public endpoints
      # -------------------------
      resources :produce_listings, only: [:index, :show]
      resources :markets,          only: [:index, :show]
      resources :truckers,         only: [:index, :show]
      get 'search', to: 'search#index'

      # -------------------------
      # Authenticated endpoints
      # -------------------------
      resources :farmer_profiles, only: [:show, :update] do
        member { get 'dashboard' }
      end

      resources :produce_listings, only: [:create, :update, :destroy] do
        resources :produce_requests, except: [:index]
      end

      resources :trucking_companies, only: [:show, :update] do
        member { get 'dashboard' }
      end

      resources :shipments do
        resources :shipment_bids, except: [:index, :show]
      end

      resources :market_profiles, only: [:show, :update] do
        member { get 'dashboard' }
      end

      resources :notifications, only: [:index, :show, :update] do
        collection { patch 'mark_all_read' }
      end

      resource :profile, only: [:show, :update] do
        patch 'complete'
      end

      get 'browse/:category', to: 'browse#show'
    end
  end

  # Health check & docs
  get 'up',       to: 'rails/health#show', as: :rails_health_check
  get 'api/docs', to: 'api/documentation#index'
end
