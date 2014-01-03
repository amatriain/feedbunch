Feedbunch::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  devise_for :users, skip: [:sessions, :passwords, :registrations, :confirmations, :unlocks]

  # Customize login, logout etc routes instead of the Devise defaults.
  # See this[https://github.com/plataformatec/devise/wiki/How-To:-Change-the-default-sign_in-and-sign_out-routes].
  devise_scope :user do
    # sessions
    get '/login' => 'devise/sessions#new', as: :new_user_session
    post '/login' => 'devise/sessions#create', as: :user_session
    delete '/logout' => 'devise/sessions#destroy', as: :destroy_user_session,via: Devise.mappings[:user].sign_out_via

    # passwords
    get '/password/new' => 'devise/passwords#new', as: :new_user_password
    post '/password/new' => 'devise/passwords#create', as: :user_password
    get '/password/edit' => 'devise/passwords#edit', as: :edit_user_password
    put '/password/edit' => 'devise/passwords#update'

    # registrations
    get '/signup' => 'devise/registrations#new', as: :new_user_registration
    post '/signup' => 'devise/registrations#create', as: :user_registration
    get '/profile' => 'devise/registrations#edit', as: :edit_user_registration
    put '/profile' => 'devise/registrations#update'
    get '/profile/cancel' => 'devise/registrations#cancel', as: :cancel_user_registration
    delete '/profile/cancel' => 'devise/registrations#destroy'

    # confirmations
    get '/resend_confirmation' => 'devise/confirmations#new', as: :new_user_confirmation
    post '/resend_confirmation' => 'devise/confirmations#create', as: :user_confirmation
    get '/confirmation' => 'devise/confirmations#show'

    # unlocks
    get '/unlock' => 'devise/unlocks#new', as: :new_user_unlock
    post '/unlock' => 'devise/unlocks#create', as: :user_unlock
    get '/unlock_account' => 'devise/unlocks#show'
  end

  # Redirect authenticated users that access the root URL to '/read'
  authenticated :user do
    get '/'  => redirect('/read')
  end

  # Static pages served with High_voltage gem
  root :to => 'high_voltage/pages#show', id: 'index'

  # Main app page
  get '/read' => 'read#index', as: :read

  # Change entries state
  match '/entries/update' => 'entries#update', via: [:patch, :put], as: 'entries_update'

  # Resourceful routes for feeds
  resources :feeds, only: [:index, :show, :create, :update, :destroy]

  # Resourceful routes for folders
  resources :folders, only: [:index, :show, :update, :create]

  # Resourceful routes for subscriptions import process status
  resource :data_imports, only: [:create, :show]

  # Resourceful routes for user data
  resource :user_data, only: [:show]

  # Resque queue monitoring app will live in the /resque subpath
  # Resque-web is only accessible for admins, see http://simple10.com/resque-admin-in-rails-3-routes-with-cancan/
  namespace :admin do
    constraints CanAccessResque do
      mount Resque::Server.new, at: 'resque'
    end
  end
end
