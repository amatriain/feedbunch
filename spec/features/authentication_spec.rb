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

    context 'sign up' do

      before :each do
        visit new_user_registration_path
      end

      it 'signs up new user' do
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: new_email, password: new_password
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Sign up'

        # test that a confirmation email is sent
        email = ActionMailer::Base.deliveries.pop
        email.present?.should be_true
        email.to.first.should eq user.email
        emailBody = Nokogiri::HTML email.body.to_s
        confirmation_link = emailBody.at_css "a[href*=\"#{confirmation_path}\"]"
        confirmation_link.present?.should be_true


        # Test that user cannot login before confirming the email address
        login_user_for_feature user
        user_should_not_be_logged

        # Follow link received by email, user should get logged in
        visit confirmation_link[:href]
        user_should_be_logged
        click_on 'Logout'

        # Test that user can login
        login_user_for_feature user
        user_should_be_logged
      end

      it 'does not sign up user if email already registered' do
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: @user.email, password: new_password
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Sign up'

        # test that a confirmation email is not sent
        email = ActionMailer::Base.deliveries.pop
        email.blank?.should be_true

        # Test that user cannot login
        login_user_for_feature user
        user_should_not_be_logged
      end

      it 'does not sign up user if both password fields do not match' do
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: new_email, password: new_password
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: 'different_password'
        click_on 'Sign up'

        # test that a confirmation email is not sent
        email = ActionMailer::Base.deliveries.pop
        email.blank?.should be_true

        # Test that user cannot login
        login_user_for_feature user
        user_should_not_be_logged
      end

    end

    context 'reset password' do

      before :each do
        visit new_user_password_path
      end

      it 'allows password reset' do
        fill_in 'Email', with: @user.email
        click_on 'Send password change email'

        # test that a confirmation email is sent
        email = ActionMailer::Base.deliveries.pop
        email.present?.should be_true
        email.to.first.should eq @user.email
        emailBody = Nokogiri::HTML email.body.to_s
        email_change_link = emailBody.at_css "a[href*=\"#{edit_user_password_path}\"]"
        email_change_link.present?.should be_true

        # follow link received by email
        visit email_change_link[:href]
        current_path.should eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Change your password'

        # after password change, user should be logged in
        current_path.should eq feeds_path
        user_should_be_logged
        click_on 'Logout'

        # test that user cannot login with old password
        login_user_for_feature @user
        user_should_not_be_logged

        # test that user can login with new password
        @user.password = new_password
        login_user_for_feature @user
        user_should_be_logged
      end

      it 'does not allow password change if both fields do not match' do
        fill_in 'Email', with: @user.email
        click_on 'Send password change email'

        # test that a confirmation email is sent
        email = ActionMailer::Base.deliveries.pop
        email.present?.should be_true
        email.to.first.should eq @user.email
        emailBody = Nokogiri::HTML email.body.to_s
        email_change_link = emailBody.at_css "a[href*=\"#{edit_user_password_path}\"]"
        email_change_link.present?.should be_true

        # follow link received by email
        visit email_change_link[:href]
        current_path.should eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: 'different_password'
        click_on 'Change your password'

        # after submit, user should NOT be logged in
        user_should_not_be_logged

        # test that user can login with old password
        login_user_for_feature @user
        user_should_be_logged
        click_on 'Logout'

        # test that user cannot login with new password
        @user.password = new_password
        login_user_for_feature @user
        user_should_not_be_logged
      end

      it 'does not send password change email to an unregistered address' do
        fill_in 'Email', with: 'unregistered_email@test.com'
        click_on 'Send password change email'

        # test that a confirmation email is not sent
        email = ActionMailer::Base.deliveries.pop
        email.blank?.should be_true
      end

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
      user_should_not_be_logged
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

    context 'edit profile' do

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
        user_should_be_logged
        click_on 'Logout'

        # test that after confirmation I cannot login with the old email
        visit confirmation_link[:href]
        login_user_for_feature @user
        user_should_not_be_logged

        # test that after confirmation I can login with the new email
        @user.email = new_email
        login_user_for_feature @user
        user_should_be_logged
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
        user_should_be_logged
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
        user_should_be_logged
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
        user_should_not_be_logged

        # test that I can login with the new password
        @user.password = new_password
        login_user_for_feature @user
        user_should_be_logged
      end

      it 'does not allow password change if current password is left blank' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Update account'
        click_on 'Logout'

        # test that I can login with the old password
        login_user_for_feature @user
        user_should_be_logged
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
        user_should_be_logged
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
        user_should_be_logged
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