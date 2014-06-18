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

  # Custom dynamic error pages
  %w( 404 422 500 ).each do |code|
    get code, :to => 'errors#show', :code => code
  end

  devise_for :users, skip: [:sessions, :passwords, :registrations, :confirmations, :unlocks, :invitations]

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
    delete '/profile' => 'devise/profiles#destroy', as: :delete_user_registration

    # confirmations
    get '/resend_confirmation' => 'devise/confirmations#new', as: :new_user_confirmation
    post '/resend_confirmation' => 'devise/confirmations#create', as: :user_confirmation
    get '/confirmation' => 'devise/confirmations#show'

    # unlocks
    get '/unlock' => 'devise/unlocks#new', as: :new_user_unlock
    post '/unlock' => 'devise/unlocks#create', as: :user_unlock
    get '/unlock_account' => 'devise/unlocks#show'

    # invitations
    post '/invitation' => 'devise/friend_invitations#create', as: :user_invitation
    patch '/invitation' => 'devise/friend_invitations#update'
    put '/invitation' => 'devise/friend_invitations#update'
    get '/accept_invitation' => 'devise/invitations#edit', as: :accept_user_invitation
    delete '/remove_invitation' => 'devise/friend_invitations#destroy', as: :remove_user_invitation
  end

  # Redirect authenticated users that access the root URL to '/read'
  authenticated :user do
    get '/'  => redirect('/read')
  end

  # Static pages served with High_voltage gem
  root :to => 'high_voltage/pages#show', id: 'index'

  # Main app page
  get '/read' => 'read#index', as: :read

  namespace :api do

    # Change entries state
    match '/entries/update' => 'entries#update', via: [:patch, :put], as: 'entries_update'

    # Resourceful routes for feeds
    resources :feeds, only: [:index, :show, :create, :update, :destroy] do
      resources :entries, only: [:index]
    end

    # Resourceful routes for folders
    resources :folders, only: [:index, :show, :update, :create] do
      resources :entries, only: [:index]
      resources :feeds, only: [:index]
    end

    # Resourceful routes for subscriptions import process state
    resource :opml_imports, only: [:show, :create, :update]

    # Resourceful routes for subscriptions export process state
    resource :opml_exports, only: [:show, :create, :update]

    # Download OPML export file
    match '/opml_exports/download' => 'opml_exports#download', via: [:get], as: 'opml_exports_download'

    # Resourceful routes for user config
    resource :user_config, only: [:show]

    # Resourceful routes for user data
    resource :user_data, only: [:show]

    # Resourceful routes for refresh_feed_job_states
    resources :refresh_feed_job_states, only: [:index, :show, :destroy]

    # Resourceful routes for subscribe_job_states
    resources :subscribe_job_states, only: [:index, :show, :destroy]

  end

  # Resque-web is only accessible for admins, see http://simple10.com/resque-admin-in-rails-3-routes-with-cancan/
  constraints CanAccessResque do
    # Resque web interface will be accessible in the /resque path
    mount Resque::Server.new, at: 'resque'
  end

  # ActiveAdmin is only accessible for admins, see http://simple10.com/resque-admin-in-rails-3-routes-with-cancan/
  constraints CanAccessActiveAdmin do
    # ActiveAdmin will be accessible in the /admin path
    ActiveAdmin.routes self
  end
end
