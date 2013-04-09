require 'spec_helper'

describe 'authentication' do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'unauthenticated visitors' do

    it 'shows a login link in the main page' do
      visit '/'
      page.should have_css "a#sign_in[href*=\"#{new_user_session_path}\"]"
    end

    it 'shows a signup link in the main page' do
      visit '/'
      page.should have_css "a#sign_up[href*=\"#{new_user_registration_path}\"]"
    end

    it 'redirects user to feeds page after a successful login' do
      login_user_for_feature @user
      current_path.should eq feeds_path
    end

    it 'stays on the login page after a failed login attempt' do
      visit '/users/sign_in'
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'wrong password!!!'
      click_on 'Sign in'
      current_path.should eq new_user_session_path
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
      page.should_not have_css "a#sign_in[href*=\"#{new_user_session_path}\"]"
    end

    it 'does not show the signup link in the main page' do
      page.should_not have_css "a#sign_up[href*=\"#{new_user_registration_path}\"]"
    end

    it 'shows navbar' do
      page.should have_css 'div.navbar'
    end

    it 'shows link to main page in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner a.brand'
      find('div.navbar div.navbar-inner a.brand').click
      current_path.should eq root_path
    end

    it 'shows logout link in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
    end

    it 'logs out user and redirects to main page' do
      find('div.navbar div.navbar-inner ul li a#sign_out').click
      current_path.should eq root_path
      page.should_not have_css 'div.navbar'
    end

    it 'shows link to feeds page in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#feeds'
      find('div.navbar div.navbar-inner ul li a#feeds').click
      current_path.should eq feeds_path
    end

    it 'shows account details link in the navbar' do
      page.should have_css 'div.navbar div.navbar-inner ul li a#my_account'
      find('div.navbar div.navbar-inner ul li a#my_account').click
      current_path.should eq edit_user_registration_path
    end

    context 'edit account' do

      before :each do
        visit '/users/edit'
      end

      it 'shows link to go to feeds list' do
        page.should have_css 'a#return'
        find('a#return').click
        current_path.should eq feeds_path
      end

      it 'saves new email' do
        pending
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        click_on 'Update account'
        click_on 'Logout'

        # test that I cannot login with the old email
        login_user_for_feature @user
        page.should have_css 'a#sign_in[href*="/users/sign_in"]'

        # test that I can login with the new email
        @user.email = new_email
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'saves new password'

      it 'deletes account'
    end

  end
end