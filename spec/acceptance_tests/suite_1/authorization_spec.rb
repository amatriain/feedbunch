require 'rails_helper'

describe 'authorization', type: :feature do

  before :each do
    @normal_user = FactoryGirl.create :user
    @admin_user = FactoryGirl.create :user_admin
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

    it 'allows access to Redmon to admin users', js: true do
      skip
      login_user_for_feature @admin_user
      visit '/redmon'
      expect(page).not_to have_content 'No route matches'
    end

    it 'does not allow access to Redmon to non-admin users', js: true do
      skip
      login_user_for_feature @normal_user
      visit '/redmon'
      expect(page).to have_content 'No route matches'
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

    it 'does not allow access to Sidekiq to non-admin users', js: true do
      skip
      login_user_for_feature @normal_user
      visit '/sidekiq'
      expect(page).to have_content 'No route matches'
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

    it 'allows access to ActiveAdmin to admin users', js: true do
      login_user_for_feature @admin_user
      visit '/admin'
      expect(page).not_to have_content 'No route matches'
    end

    it 'does not allow access to ActiveAdmin to non-admin users', js: true do
      skip
      login_user_for_feature @normal_user
      visit '/admin'
      expect(page).to have_content 'No route matches'
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

    it 'allows access to PgHero to admin users', js: true do
      skip
      login_user_for_feature @admin_user
      visit '/pghero'
      expect(page).not_to have_content 'No route matches'
    end

    it 'does not allow access to PgHero to non-admin users', js: true do
      skip
      login_user_for_feature @normal_user
      visit '/pghero'
      expect(page).to have_content 'No route matches'
    end
  end
end