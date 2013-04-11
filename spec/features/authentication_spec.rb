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
      visit new_user_session_path
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
    end

    it 'redirects to feeds list after a successful login' do
      current_path.should eq feeds_path
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
      visit '/'
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
        visit edit_user_registration_path
      end

      it 'shows navbar' do
        page.should have_css 'div.navbar'
      end

      it 'shows link to go to feeds list' do
        page.should have_css 'a#return'
        find('a#return').click
        current_path.should eq feeds_path
      end

      it 'allows email change' do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        click_on 'Logout'

        # test that a confirmation email is sent
        email = ActionMailer::Base.deliveries.pop
        email.present?.should be_true
        email.to.first.should eq new_email
        emailBody = Nokogiri::HTML email.body.to_s
        confirmation_link = emailBody.at_css "a[href*=\"#{confirmation_path}\"]"
        confirmation_link.present?.should be_true

        # test that before confirmation I can login with the old email
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
        click_on 'Logout'

        # test that after confirmation I cannot login with the old email
        visit confirmation_link[:href]
        login_user_for_feature @user
        page.should_not have_css 'div.navbar div.navbar-inner ul li a#sign_out'

        # test that after confirmation I can login with the new email
        @user.email = new_email
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'does not allow email change if current password is left blank' do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        click_on 'Update account'
        click_on 'Logout'

        # test that a confirmation email is not sent
        ActionMailer::Base.deliveries.blank?.should be_true

        # test that I can login with the old email
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
        click_on 'Logout'
      end

      it 'does not allow email change if current password is filled with wrong password' do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        fill_in 'Current password', with: 'wrong_password'
        click_on 'Update account'
        click_on 'Logout'

        # test that a confirmation email is not sent
        ActionMailer::Base.deliveries.blank?.should be_true

        # test that I can login with the old email
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
        click_on 'Logout'
      end

      it 'allows password change' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        click_on 'Logout'

        # test that I cannot login with the old password
        login_user_for_feature @user
        page.should_not have_css 'div.navbar div.navbar-inner ul li a#sign_out'

        # test that I can login with the new password
        @user.password = new_password
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'does not allow password change if current password is left blank' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Update account'
        click_on 'Logout'

        # test that I can login with the old password
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'does not allow password change if current password is filled with wrong password' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        fill_in 'Current password', with: 'wrong_password'
        click_on 'Update account'
        click_on 'Logout'

        # test that I can login with the old password
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'does not allow password change if both password fields do not match' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: 'different_new_password'
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        click_on 'Logout'

        # test that I can login with the old password
        login_user_for_feature @user
        page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
      end

      it 'deletes account', js: true do
        handle_js_confirm do
          click_on 'Cancel account'
        end
        User.all.blank?.should be_true
      end

      it 'changes user language'

    end
  end
end