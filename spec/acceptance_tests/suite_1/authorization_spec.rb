require 'rails_helper'

describe 'authorization', type: :feature do

  before :each do
    @normal_user = FactoryGirl.create :user
    @admin_user = FactoryGirl.create :user_admin
  end

  # TODO delete this context after migration from Resque to Sidekiq is completed
  context 'Resque access' do

    it 'shows Resque link to admin users' do
      login_user_for_feature @admin_user
      visit read_path

      expect(page).to have_css 'a[href="/resque"]'
    end

    it 'does not show Resque link to non-admin users' do
      login_user_for_feature @normal_user
      visit read_path

      expect(page).not_to have_css 'a[href="/resque"]'
    end

    it 'does not allow access to Resque to non-admin users' do
      login_user_for_feature @normal_user
      expect {visit '/resque'}.to raise_error ActionController::RoutingError
    end

  end

  context 'Sidekiq access' do

    it 'shows Sidekiq link to admin users' do
      login_user_for_feature @admin_user
      visit read_path

      expect(page).to have_css 'a[href^="/sidekiq"]'
    end

    it 'does not show Sidekiq link to non-admin users' do
      login_user_for_feature @normal_user
      visit read_path

      expect(page).not_to have_css 'a[href="/sidekiq"]'
    end

    it 'does not allow access to Resque to non-admin users' do
      login_user_for_feature @normal_user
      expect {visit '/sidekiq'}.to raise_error ActionController::RoutingError
    end

  end

  context 'ActiveAdmin access' do

    it 'shows ActiveAdmin link to admin users' do
      login_user_for_feature @admin_user
      visit read_path

      expect(page).to have_css 'a[href="/admin"]'
    end

    it 'does not show ActiveAdmin link to non-admin users' do
      login_user_for_feature @normal_user
      visit read_path

      expect(page).not_to have_css 'a[href="/admin"]'
    end

    it 'allows access to ActiveAdmin to admin users' do
      login_user_for_feature @admin_user
      expect {visit '/admin'}.not_to raise_error
    end

    it 'does not allow access to ActiveAdmin to non-admin users' do
      login_user_for_feature @normal_user
      expect {visit '/admin'}.to raise_error ActionController::RoutingError
    end
  end
end