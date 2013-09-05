require 'spec_helper'

describe 'authentication' do

  before :each do
    @user = FactoryGirl.create :user
    # Remove emails stil in the mail queue
    ActionMailer::Base.deliveries.clear
  end

  context 'unauthenticated visitors' do

    it 'shows a link to the app in the main page' do
      visit '/'
      within "a#sign_in[href*=\"#{feeds_path}\"]" do
        page.should have_content 'Sign in'
      end
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
        confirmation_link = mail_should_be_sent path: confirmation_path, to: user.email

        # Test that user cannot login before confirming the email address
        failed_login_user_for_feature new_email, new_password

        # Follow link received by email, user should get logged in
        visit confirmation_link
        user_should_be_logged_in
        click_on 'Logout'

        # Test that user can login
        login_user_for_feature user
      end

      it 'does not sign up user if email already registered' do
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: @user.email, password: new_password
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Sign up'

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # Test that user cannot login
        failed_login_user_for_feature user.email, new_password
      end

      it 'does not sign up user if both password fields do not match' do
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        different_password = 'different_password'
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: different_password
        click_on 'Sign up'

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # Test that user cannot login
        failed_login_user_for_feature new_email, new_password
        failed_login_user_for_feature new_email, different_password
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
        email_change_link = mail_should_be_sent path: edit_user_password_path, to: @user.email

        # follow link received by email
        visit email_change_link
        current_path.should eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Change your password'

        # after password change, user should be logged in
        current_path.should eq feeds_path
        user_should_be_logged_in
        click_on 'Logout'

        # test that user cannot login with old password
        failed_login_user_for_feature @user.email, @user.password

        # test that user can login with new password
        @user.password = new_password
        login_user_for_feature @user
      end

      it 'does not allow password change if both fields do not match' do
        fill_in 'Email', with: @user.email
        click_on 'Send password change email'

        # test that a confirmation email is sent
        email_change_link = mail_should_be_sent path: edit_user_password_path, to: @user.email

        # follow link received by email
        visit email_change_link
        current_path.should eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        different_password = 'different_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: different_password
        click_on 'Change your password'

        # after submit, user should NOT be logged in
        user_should_not_be_logged_in

        # test that user can login with old password
        login_user_for_feature @user
        click_on 'Logout'

        # test that user cannot login with new password
        failed_login_user_for_feature @user.email, new_password
        failed_login_user_for_feature @user.email, different_password
      end

      it 'does not send password change email to an unregistered address' do
        fill_in 'Email', with: 'unregistered_email@test.com'
        click_on 'Send password change email'

        # test that a confirmation email is not sent
        mail_should_not_be_sent
      end

    end

    context 'resend confirmation email' do

      it 'sends confirmation email to unconfirmed user' do
        # sign up new user
        visit new_user_registration_path
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: new_email, password: new_password
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Sign up'

        # Remove confirmation mails sent on signup from mail queue
        ActionMailer::Base.deliveries.clear

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: new_email
        click_on 'Confirm email address'

        # Check that confirmation email is sent
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email

        # Check that user cannot log in before confirming
        failed_login_user_for_feature new_email, new_password

        # Confirm email, user should be logged in automatically
        visit confirmation_link
        user_should_be_logged_in

        # Check that user can log in
        click_on 'Logout'
        visit new_user_session_path
        login_user_for_feature user
      end

      it 'does not send confirmation email to a confirmed user' do
        # sign up new user
        visit new_user_registration_path
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryGirl.build :user, email: new_email, password: new_password
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Sign up'

        # Confirm email
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email
        visit confirmation_link
        click_on 'Logout'

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: new_email
        click_on 'Confirm email address'

        # Check that no email is sent
        mail_should_not_be_sent
      end

      it 'does not send confirmation email to an unregistered user' do
        unregistered_email = 'unregistered@test.com'

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: unregistered_email
        click_on 'Confirm email address'

        # Check that no email is sent
        mail_should_not_be_sent
      end

    end

    context 'user locking' do

      it 'locks user after too many failed authentication attempts' do
        # lock user after 5 failed authentication attempts
        wrong_password = 'wrong_password'
        (1..6).each do
          failed_login_user_for_feature @user.email, wrong_password
        end

        # Check that user is locked
        failed_login_user_for_feature @user.email, @user.password
      end

      it 'automatically sends unlock email to a locked user' do
        # Lock user after 5 failed authentication attempts
        # The next authentication attempt the app sends an unlock email to
        # notify the user and give him the chance to unlock his account.
        wrong_password = 'wrong_password'
        (1..6).each do
          failed_login_user_for_feature @user.email, wrong_password
        end

        # Check that unlock email is sent
        unlock_link = mail_should_be_sent path: unlock_account_path, to: @user.email

        # Check that can log in after following unlock link
        visit unlock_link
        login_user_for_feature @user
      end

      it 'resends unlock email to a locked user' do
        # lock user after 5 failed authentication attempts
        wrong_password = 'wrong_password'
        (1..6).each do
          failed_login_user_for_feature @user.email, wrong_password
        end

        # Remove aumatically sent email from queue
        ActionMailer::Base.deliveries.clear

        # Ask for an unlock email to be sent again
        visit new_user_unlock_path
        fill_in 'Email', with: @user.email
        click_on 'Send unlock email'

        # Check that unlock email is sent
        unlock_link = mail_should_be_sent path: unlock_account_path, to: @user.email

        # Check that can log in after following unlock link
        visit unlock_link
        login_user_for_feature @user
      end

      it 'does not send unlock email to an unlocked user' do
        # Ask for an unlock email to be sent
        visit new_user_unlock_path
        fill_in 'Email', with: @user.email
        click_on 'Send unlock email'

        # Check that unlock email is not sent
        mail_should_not_be_sent
      end

      it 'does not send unlock email to an unregistered user' do
        # Ask for an unlock email to be sent
        visit new_user_unlock_path
        fill_in 'Email', with: 'unregistered@test.com'
        click_on 'Send unlock email'

        # Check that unlock email is not sent
        mail_should_not_be_sent
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
      page.should have_css 'div.navbar div.navbar-header a.navbar-brand'
      find('div.navbar div.navbar-header a.navbar-brand').click
      current_path.should eq root_path
    end

    it 'shows logout link in the navbar' do
      page.should have_css 'div.navbar ul li a#sign_out'
    end

    it 'logs out user and redirects to main page' do
      find('div.navbar ul li a#sign_out').click
      current_path.should eq root_path
      user_should_not_be_logged_in
    end

    it 'shows account details link in the navbar' do
      page.should have_css 'div.navbar ul li a#my_account'
      find('div.navbar ul li a#my_account').click
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
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email

        # test that before confirmation I can login with the old email
        login_user_for_feature @user
        click_on 'Logout'

        # test that after confirmation I cannot login with the old email
        visit confirmation_link
        failed_login_user_for_feature @user.email, @user.password

        # test that after confirmation I can login with the new email
        @user.email = new_email
        login_user_for_feature @user
      end

      it 'does not allow email change if current password is left blank' do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        click_on 'Update account'
        click_on 'Logout'

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # test that I can login with the old email
        login_user_for_feature @user
      end

      it 'does not allow email change if current password is filled with wrong password' do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        fill_in 'Current password', with: 'wrong_password'
        click_on 'Update account'
        click_on 'Logout'

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # test that I can login with the old email
        login_user_for_feature @user
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
        failed_login_user_for_feature @user, @user.password

        # test that I can login with the new password
        @user.password = new_password
        login_user_for_feature @user
      end

      it 'does not allow password change if current password is left blank' do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Confirm password', with: new_password
        click_on 'Update account'
        click_on 'Logout'

        # test that I can login with the old password
        login_user_for_feature @user
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