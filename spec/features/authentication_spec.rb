require 'spec_helper'

describe 'authentication' do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'unauthenticated visitors' do

    it 'shows a login link in the main page' do
      visit '/'
      page.should have_css 'a#sign_in[href*="/users/sign_in"]'
    end

    it 'shows a signup link in the main page' do
      visit '/'
      page.should have_css 'a#sign_up[href*="/users/sign_up"]'
    end

    it 'redirects user to feeds page after a successful login' do
      login_user_for_feature @user
      current_path.should eq '/feeds'
    end

    it 'stays on the login page after a failed login attempt' do
      visit '/users/sign_in'
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'wrong password!!!'
      click_on 'Sign in'
      current_path.should eq '/users/sign_in'
    end

    it 'does not show navbar' do
      visit '/'
      page.should_not have_css 'div.navbar'
    end

  end

  context 'authenticated users' do

    before :each do
      login_user_for_feature @user
      visit '/'
    end

    it 'does not show the login link in the main page' do
      page.should_not have_css 'a#sign_in[href*="/users/sign_in"]'
    end

    it 'does not show the signup link in the main page' do
      page.should_not have_css 'a#sign_up[href*="/users/sign_up"]'
    end

    it 'shows navbar' do
      page.should have_css 'div.navbar'
    end

    it 'shows link to main page in the navbar' do
      find('div.navbar div.navbar-inner a.brand').click
      current_path.should eq '/'
    end

    it 'shows signout link in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
    end

    it 'signs out user and redirects to main page' do
      find('div.navbar div.navbar-inner ul li a#sign_out').click
      current_path.should eq '/'
      page.should_not have_css 'div.navbar'
    end

    it 'shows link to feeds page in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#feeds'
    end

    it 'shows the feeds page when clicking on the Feeds link' do
      find('div.navbar div.navbar-inner ul li a#feeds').click
      current_path.should eq feeds_path
    end

    it 'shows account details link in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#my_account'
    end

    it 'shows the account details page when clicking on the My Account link' do
      find('div.navbar div.navbar-inner ul li a#my_account').click
      current_path.should eq edit_user_registration_path
    end

    context 'edit account' do

      it 'saves new email'

      it 'saves new password'

      it 'deletes account'
    end

  end
end