Rails.application.routes.draw do
  scope "(:locale)", locale: /es|en/ do
    devise_for :users, controllers: { registrations: "users/registrations" }
    delete "/users/delete_account", to: "users/registrations#destroy", as: :delete_account


    root to: "grupos#dashboard"

    get "/buscar", to: "busqueda#index", as: "buscar"

    resources :grupos, path: "categorias", only: [ :index, :show ] do
      resources :products, path: "productos", only: [ :index, :show ], module: :grupos
    end

    resources :products, path: "productos", only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets

    resources :clientes, only: [ :index, :update, :show ] # ruta vista perfil usuarios
    
    # Rastreador de pedidos (para usuarios y invitados)
    resources :order_tracking, only: [:index] do
      collection do
        get :search
      end
    end
    
    resources :direccions, only: [ :index, :create, :destroy ] do
      member do
        patch :set_principal
      end
    end

    # Ruta especial para combos
    get "/combos", to: "products#combos", as: "combos"

    resource :carrito, only: [ :show ] do
      post :aplicar_cupon
      delete :quitar_cupon
    end
    resources :carrito_items, only: [ :create, :update, :destroy ] do
      member do
        put :incrementar
      end
    end

    resources :orders, param: :code, only: [ :show, :create ] do
      resource :payments, path: "payment", only: [ :new, :create ], module: :orders do
        get :status
        patch :cancel
        patch :confirm_cash_payment
        patch :finalize_cash_payment
      end
    end

    post "/wompi/webhook", to: "wompi#webhook"
  end

  # resources :pedidos, only: [:create] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  namespace :dashboard do
    root to: "dashboard#index"
    resources :grupos, path: "grupos"
    resources :ingredientes
    resources :users
    resources :banners
    resources :sedes
    resources :coupons do
      member do
        patch :toggle_activo
      end
    end
    resources :orders do
      collection do
        get :employee
      end
      member do
        patch :cambiar_estado
        patch :cancelar
        patch :finalizar
      end
    end
    resources :products, path: "productos" do
      member do
        patch :toggle_disponibilidad # Cambia el nombre aquí
      end
    end
  end

  # API routes (outside locale scope)
  namespace :api do
    namespace :v1 do
      get "health", to: "health#check"

      # Authentication endpoints
      post "login",  to: "auth#login"
      post "logout", to: "auth#logout"
      post "register", to: "auth#register"
      post "forgot_password", to: "auth#forgot_password"
      post "reset_password", to: "auth#reset_password"
      post "resend_confirmation", to: "auth#resend_confirmation"
      get "confirm_email", to: "auth#confirm_email"

      get "buscar", to: "busqueda#index"

      get "combos", to: "productos#combos"

      get "banners", to: "banners#index"

      get "sedes", to: "sedes#index"

      get "config/google_map_key", to: "config#google_map_key"

      resources :grupos, path: "categorias", only: [ :index, :show ] do
        resources :products, path: "productos", only: [ :index, :show ], module: :grupos
      end
      resources :orders, param: :code, only: [ :index, :show, :create ] do
        member do
          patch :cancel
          patch :update_address
        end
        # Payment endpoints
        resources :payments, only: [ :create ], param: :id do
          collection do
            get :status
            post :cancel
          end
        end
      end

      # Wompi webhook endpoint
      post "webhooks/wompi", to: "payments#webhook"
    end
  end
end
