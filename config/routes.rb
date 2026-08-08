Rails.application.routes.draw do
  # Health check for the reverse proxy / uptime monitor.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA: installable to a phone home screen.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # First-boot wizard: family, owner account, children.
  resource :setup, only: [ :show, :create ], controller: "setup"

  # Parent authentication (Rails 8 built-in auth).
  resource :session
  resources :passwords, param: :token

  namespace :dojo do
    resource :dashboard, only: :show, controller: "dashboard"

    resources :children do
      member do
        get :report, to: "reports#show"
        post :restore
      end
    end

    resources :behaviors do
      collection { patch :reorder }
      member { post :restore }
    end

    resources :point_events, only: [ :index, :new, :create ] do
      member { post :revert }
    end

    resources :rewards do
      member { post :restore }
    end

    resources :redemptions, only: [ :index, :create, :update ]

    resource :settings, only: [ :show, :update ], controller: "settings"
    resources :users, only: [ :index, :new, :create, :destroy ]
  end

  # Read-only kid view, unlocked with a per-child PIN on a shared tablet.
  namespace :kids do
    root "sessions#new"
    resource :session, only: [ :new, :create, :destroy ], controller: "sessions"
    resource :dashboard, only: :show, controller: "dashboard"
    resources :redemptions, only: [ :create ]
  end

  root "dojo/dashboard#show"
end
