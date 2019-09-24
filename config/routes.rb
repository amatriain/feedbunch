# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'sidekiq-cron'

Rails.application.routes.draw do

  # Custom dynamic error pages
  %w( 404 422 500 ).each do |code|
    get code, :to => 'errors#show', :code => code
  end

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
    post '/signup' => 'feedbunch_auth/registrations#create', as: :user_registration
    get '/profile' => 'devise/registrations#edit', as: :edit_user_registration
    put '/profile' => 'devise/registrations#update'
    delete '/profile' => 'feedbunch_auth/registrations#destroy', as: :delete_user_registration

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
  root to: 'high_voltage/pages#show', id: 'index'
  get '/signup-success' => 'high_voltage/pages#show', id: 'signup-success', as: :signup_success

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
    resource :user_config, only: [:show, :update]

    # Resourceful routes for user data
    resource :user_data, only: [:show]

    # Resourceful routes for refresh_feed_job_states
    resources :refresh_feed_job_states, only: [:index, :show, :destroy]

    # Resourceful routes for subscribe_job_states
    resources :subscribe_job_states, only: [:index, :show, :destroy]

    # Resourceful routes for application tours i18n strings.
    match '/tours/main' => 'tours#show_main', via: [:get], as: 'tours_show_main'
    match '/tours/mobile' => 'tours#show_mobile', via: [:get], as: 'tours_show_mobile'
    match '/tours/feed' => 'tours#show_feed', via: [:get], as: 'tours_show_feed'
    match '/tours/entry' => 'tours#show_entry', via: [:get], as: 'tours_show_entry'
    match '/tours/kb_shortcuts' => 'tours#show_kb_shortcuts', via: [:get], as: 'tours_show_kb_shortcuts'
  end

  # Restrict access to Sidekiq web ui to admin users only
  constraints CanAccessSidekiq do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Redmon is only accessible for admins
  constraints CanAccessRedmon do
    mount Redmon::App => '/redmon'
  end

  # ActiveAdmin is only accessible for admins
  constraints CanAccessActiveAdmin do
    # ActiveAdmin will be accessible in the /admin path
    ActiveAdmin.routes self
  end

  # PgHero is only accessible for admins
  constraints CanAccessPgHero do
    mount PgHero::Engine, at: 'pghero'
  end
end
