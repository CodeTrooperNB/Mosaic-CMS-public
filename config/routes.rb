# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint for monitoring
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise routes for AdminUser authentication
  devise_for :admin_users, path: "admin/auth", controllers: {
    sessions: "admin/devise/sessions",
    passwords: "admin/devise/passwords",
    registrations: "admin/devise/registrations"
  }

  # Admin namespace routes (CMS admin interface)
  namespace :admin do
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :admin_users, except: [:show] do
      member do
        patch :toggle_role
      end
    end
    resources :pages do
      member do
        patch :update_hierarchy
      end
      resources :page_pods, only: [:create, :destroy] do
        collection do
          patch :sort
        end
      end
    end
    resources :pods, only: [:index, :new, :create, :edit, :update, :destroy] do
      collection do
        post :array_item_form
        post :preview
      end
    end
    resources :blogs
    resources :blog_comments, only: [:update, :destroy]
    resources :enquiries, only: [:index, :show, :destroy] do
      member do
        patch :mark_as_read
        patch :mark_as_resolved
        patch :mark_as_spam
        patch :mark_as_not_spam
      end
      collection do
        delete :clear_spam
      end
    end
    resources :settings, only: [:index]
    post "image_uploads", to: "image_uploads#create"
    get "image_attachments/:key", to: "image_attachments#show"
    get "image_attachments/:key/:variant", to: "image_attachments#show"
  end

  # ###########################################
  # ########## TEST FRONTEND ROUTES ###########
  # ###########################################

  #  hello_world routes for CMS delegation/testing
  resources :hello_world, only: [:index, :show]

  # ############################################
  # ############ TEST ROUTES END #############
  # ############################################

  # ###########################################
  # ##### CUSTOM FRONTEND ROUTES GO HERE ######
  # ###########################################

  # Application-specific routes (these take precedence over CMS)
  # E-commerce routes
  resources :products, only: [:index, :show] do
    collection do
      get :search
    end
  end

  resource :cart, only: [:show, :create, :update, :destroy] do
    member do
      post :add_item
      patch :update_item
      delete :remove_item
      delete :clear
    end
  end

  resource :checkout, only: [:show, :create] do
    member do
      post :apply_coupon
      delete :remove_coupon
      post :calculate_shipping
      post :process_payment
    end
  end

  # Customer management routes
  resources :customers, only: [:show, :create] do
    collection do
      post :login
      post :signup
      delete :logout
    end
    member do
      patch :update_profile
    end
  end

  resources :addresses, only: [:index, :show, :create, :update, :destroy] do
    member do
      patch :set_default
    end
  end

  resources :orders, only: [:index, :show] do
    member do
      post :request_refund
    end
  end

  resources :refunds, only: [:index, :show, :create]

  resources :blogs, only: [:index, :show] do
    resources :comments, only: [:create], module: :blogs
  end

  resources :enquiries, only: [:create]

  # ############################################
  # ############ CUSTOM ROUTES END #############
  # ############################################

  # Sidekiq Web UI (protected by admin authentication)
  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/admin/sidekiq"
  else
    require "sidekiq/web"
    authenticate :admin_user, ->(admin_user) { admin_user.admin? } do
      mount Sidekiq::Web => "/admin/sidekiq"
    end
  end

  # CMS routes (catch-all, must be last)
  root "pages#home"

  # This catches all remaining paths and tries to serve them as CMS pages
  get "*path", to: "pages#show", constraints: lambda { |req|
    # Only match if it doesn't start with admin, rails, or other reserved paths
    !req.path.starts_with?("/admin") &&
      !req.path.starts_with?("/rails") &&
      !req.path.starts_with?("/assets")
  }
end
