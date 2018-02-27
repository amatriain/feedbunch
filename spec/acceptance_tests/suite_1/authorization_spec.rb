require 'rails_helper'

describe 'routes', type: :request do

  before :each do
    Warden.test_mode!
    @normal_user = FactoryBot.create :user
    @admin_user = FactoryBot.create :user_admin
  end

  context 'Redmon access' do

    it 'allows access to Redmon to admin users' do
      login_as @admin_user
      expect{get '/redmon'}.not_to raise_error
    end

    it 'does not allow access to Redmon to non-admin users' do
      login_as @normal_user
      expect{get '/redmon'}.to raise_error ActionController::RoutingError
    end

  end

  context 'Sidekiq access' do

    it 'does not allow access to Sidekiq to non-admin users' do
      login_as @normal_user
      expect{get '/sidekiq'}.to raise_error ActionController::RoutingError
    end
  end

  context 'ActiveAdmin access' do

    it 'allows access to ActiveAdmin to admin users', js: true do
      login_as @admin_user
      expect{get '/admin'}.not_to raise_error
    end

    it 'does not allow access to ActiveAdmin to non-admin users', js: true do
      login_as @normal_user
      expect{get '/admin'}.to raise_error ActionController::RoutingError
    end
  end

  context 'PgHero access' do

    it 'allows access to PgHero to admin users', js: true do
      login_as @admin_user
      expect{get '/pghero'}.not_to raise_error ActionController::RoutingError
    end

    it 'does not allow access to PgHero to non-admin users', js: true do
      login_as @normal_user
      expect{get '/pghero'}.to raise_error ActionController::RoutingError
    end
  end

end

describe 'authorized links', type: :feature do

  before :each do
    @normal_user = FactoryBot.create :user
    @admin_user = FactoryBot.create :user_admin
  end

  context 'Redmon access' do

    it 'shows Redmon link to admin users', js: true do
      login_user_for_feature @admin_user
      visit read_path
      open_user_menu

      expect(page).to have_css 'a[href^="/redmon"]'
    end

    it 'does not show Redmon link to non-admin users', js: true do
      login_user_for_feature @normal_user
      visit read_path
      open_user_menu

      expect(page).to have_no_css 'a[href^="/redmon"]'
    end

  end

  context 'Sidekiq access' do

    it 'shows Sidekiq link to admin users', js: true do
      login_user_for_feature @admin_user
      visit read_path
      open_user_menu

      expect(page).to have_css 'a[href^="/sidekiq"]'
    end

    it 'does not show Sidekiq link to non-admin users', js: true do
      login_user_for_feature @normal_user
      visit read_path
      open_user_menu

      expect(page).to have_no_css 'a[href^="/sidekiq"]'
    end

  end

  context 'ActiveAdmin access' do

    it 'shows ActiveAdmin link to admin users', js: true do
      login_user_for_feature @admin_user
      visit read_path
      open_user_menu

      expect(page).to have_css 'a[href="/admin"]'
    end

    it 'does not show ActiveAdmin link to non-admin users', js: true do
      login_user_for_feature @normal_user
      visit read_path
      open_user_menu

      expect(page).to have_no_css 'a[href="/admin"]'
    end

  end

  context 'PgHero access' do

    it 'shows PgHero link to admin users', js: true do
      login_user_for_feature @admin_user
      visit read_path
      open_user_menu

      expect(page).to have_css 'a[href="/pghero"]'
    end

    it 'does not show PgHero link to non-admin users', js: true do
      login_user_for_feature @normal_user
      visit read_path
      open_user_menu

      expect(page).to have_no_css 'a[href="/pghero"]'
    end

  end
end