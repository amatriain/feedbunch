require 'rails_helper'

describe 'authentication', type: :feature do

  before :each do
    @user = FactoryBot.create :user
    # Remove emails stil in the mail queue
    ActionMailer::Base.deliveries.clear
  end

  context 'unauthenticated visitors' do

    it 'does not redirect to read view when user tries to access the root URL', js: true do
      visit root_path
      expect(current_path).to eq root_path
    end

    it 'shows a link to the app in the main page', js: true do
      visit '/'
      within "a#sign_in[href*=\"#{read_path}\"]" do
        expect(page).to have_content 'Log in'
      end
    end

    it 'shows a signup link in the main page', js: true do
      visit '/'
      expect(page).to have_css "a#sign_up[href*=\"#{new_user_registration_path}\"]"
    end

    it 'redirects user to feeds page after a successful login', js: true do
      login_user_for_feature @user
      expect(current_path).to eq read_path
    end

    it 'stays on the login page after a failed login attempt', js: true do
      visit new_user_session_path
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'wrong password!!!'
      click_on 'Log in'
      expect(current_path).to eq new_user_session_path
    end

    it 'does not show navbar', js: true do
      visit '/'
      expect(page).to have_no_css 'div.navbar'
    end

    context 'sign up' do

      before :each do
        visit new_user_registration_path
      end

      it 'signs up new user', js: true do
        new_email = 'new_email@test.com'
        new_password = 'new_password'

        sign_up_for_feature new_email, new_password

        login_user_for_feature @user
        user_should_be_logged_in
      end

      it 'redirects to signup success view after a successful signup', js: true do
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        sign_up_for_feature new_email, new_password, confirm_account: false
        expect(current_path).to eq signup_success_path
      end

      it 'does not sign up user if email already registered', js: true do
        new_password = 'new_password'
        user = FactoryBot.build :user, email: @user.email, password: new_password
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: new_password
        fill_in 'Password (again)', with: new_password
        show_sign_up_button
        click_on 'Sign up'

        expect(page).to have_text 'Email has already been taken'

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # Test that user cannot login
        failed_login_user_for_feature user.email, new_password
      end

      it 'does not sign up user if both password fields do not match', js: true do
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        different_password = 'different_password'
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Password (again)', with: different_password
        show_sign_up_button
        click_on 'Sign up'

        expect(page).to have_text "Password confirmation doesn't match Password"

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

      it 'allows password reset', js: true do
        fill_in 'Email', with: @user.email
        click_on 'Reset password'

        # test that a confirmation email is sent
        password_change_link = mail_should_be_sent path: edit_user_password_path, to: @user.email
        password_change_url = get_password_change_link_from_email password_change_link

        # follow link received by email
        visit password_change_url
        expect(current_path).to eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: new_password
        click_on 'Change your password'

        # after password change, user should be logged in
        expect(current_path).to eq read_path
        user_should_be_logged_in
        logout_user_for_feature

        # test that user cannot login with old password
        failed_login_user_for_feature @user.email, @user.password

        # test that user can login with new password
        @user.password = new_password
        login_user_for_feature @user
      end

      it 'does not allow password change if both fields do not match', js: true do
        fill_in 'Email', with: @user.email
        click_on 'Reset password'

        # test that a confirmation email is sent
        email_change_link = mail_should_be_sent path: edit_user_password_path, to: @user.email
        email_change_url = get_password_change_link_from_email email_change_link

        # follow link received by email
        visit email_change_url
        expect(current_path).to eq edit_user_password_path

        # submit password change form
        new_password = 'new_password'
        different_password = 'different_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: different_password
        click_on 'Change your password'

        # after submit, user should NOT be logged in
        user_should_not_be_logged_in

        # test that user can login with old password
        login_user_for_feature @user
        logout_user_for_feature

        # test that user cannot login with new password
        failed_login_user_for_feature @user.email, new_password
        failed_login_user_for_feature @user.email, different_password
      end

      it 'does not send password change email to an unregistered address', js: true do
        fill_in 'Email', with: 'unregistered_email@test.com'
        click_on 'Reset password'

        # test that a confirmation email is not sent
        mail_should_not_be_sent
      end

    end

    context 'resend confirmation email' do

      it 'sends confirmation email to unconfirmed user', js: true do
        # sign up new user
        visit new_user_registration_path
        close_cookies_alert
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryBot.build :user, email: new_email, password: new_password
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Password (again)', with: new_password
        show_sign_up_button
        click_on 'Sign up'

        # Remove confirmation mails sent on signup from mail queue
        ActionMailer::Base.deliveries.clear

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: new_email
        click_on 'Confirm email'

        # Check that confirmation email is sent
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email
        confirmation_url = get_confirm_address_link_from_email confirmation_link

        # Check that user cannot log in before confirming
        failed_login_user_for_feature new_email, new_password

        # Confirm email, user should be able to log in afterwards
        visit confirmation_url

        # Check that user can log in
        login_user_for_feature user
      end

      it 'does not send confirmation email to a confirmed user', js: true do
        # sign up new user
        visit new_user_registration_path
        new_email = 'new_email@test.com'
        new_password = 'new_password'
        user = FactoryBot.build :user, email: new_email, password: new_password
        fill_in 'Email', with: new_email
        fill_in 'Password', with: new_password
        fill_in 'Password (again)', with: new_password
        show_sign_up_button
        click_on 'Sign up'

        # Confirm email
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email
        confirmation_url = get_confirm_address_link_from_email confirmation_link
        visit confirmation_url

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: new_email
        click_on 'Confirm email'

        # Check that no email is sent
        mail_should_not_be_sent
      end

      it 'does not send confirmation email to an unregistered user', js: true do
        unregistered_email = 'unregistered@test.com'

        # Ask for resend of confirmation email
        visit new_user_confirmation_path
        fill_in 'Email', with: unregistered_email
        click_on 'Confirm email'

        # Check that no email is sent
        mail_should_not_be_sent
      end

    end

    context 'user locking' do

      it 'locks user after too many failed authentication attempts', js: true do
        # lock user after 5 failed authentication attempts
        wrong_password = 'wrong_password'
        (1..6).each do
          failed_login_user_for_feature @user.email, wrong_password
        end

        # Check that user is locked
        failed_login_user_for_feature @user.email, @user.password
      end

      it 'automatically sends unlock email to a locked user', js: true do
        # Lock user after 5 failed authentication attempts
        # The next authentication attempt the app sends an unlock email to
        # notify the user and give him the chance to unlock his account.
        wrong_password = 'wrong_password'
        (1..6).each do
          failed_login_user_for_feature @user.email, wrong_password
        end

        # Check that unlock email is sent
        unlock_link = mail_should_be_sent path: unlock_account_path, to: @user.email
        unlock_url = get_unlock_link_from_email unlock_link

        # Check that can log in after following unlock link
        visit unlock_url
        login_user_for_feature @user
      end

      it 'resends unlock email to a locked user', js: true do
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
        click_on 'Unlock account'

        # Check that unlock email is sent
        unlock_link = mail_should_be_sent path: unlock_account_path, to: @user.email
        unlock_url = get_unlock_link_from_email unlock_link

        # Check that can log in after following unlock link
        visit unlock_url
        login_user_for_feature @user
      end

      it 'does not send unlock email to an unlocked user', js: true do
        # Ask for an unlock email to be sent
        visit new_user_unlock_path
        fill_in 'Email', with: @user.email
        click_on 'Unlock account'

        # Check that unlock email is not sent
        mail_should_not_be_sent
      end

      it 'does not send unlock email to an unregistered user', js: true do
        # Ask for an unlock email to be sent
        visit new_user_unlock_path
        fill_in 'Email', with: 'unregistered@test.com'
        click_on 'Unlock account'

        # Check that unlock email is not sent
        mail_should_not_be_sent
      end

    end

  end

  context 'authenticated users' do

    before :each do
      login_user_for_feature @user
    end

    it 'redirects to read view after a successful login', js: true do
      expect(current_path).to eq read_path
    end

    it 'redirects to read view if user tries to access the root URL', js: true do
      visit root_path
      expect(current_path).to eq read_path
    end

    it 'redirects to login page if an AJAX request is returned an HTTP 401 Unauthorized', js: true do
      # clear session cookies to force a 401 response
      clear_cookies
      go_to_start_page

      expect(page).to have_text 'Log in'
      expect(current_path).to eq new_user_session_path
    end

    it 'does not show the login link in the main page', js: true do
      expect(page).to have_no_css "a#sign_in[href*=\"#{new_user_session_path}\"]"
    end

    it 'does not show the signup link in the main page', js: true do
      expect(page).to have_no_css "a#sign_up[href*=\"#{new_user_registration_path}\"]"
    end

    it 'shows navbar', js: true do
      expect(page).to have_css 'div.navbar'
    end

    it 'shows link to feeds page in the navbar', js: true do
      expect(page).to have_css 'div.navbar div.navbar-header a.navbar-brand'
      find('div.navbar div.navbar-header a.navbar-brand').click
      expect(current_path).to eq read_path
    end

    it 'shows logout link in the navbar', js: true do
      open_user_menu
      expect(page).to have_css 'div.navbar ul li a#sign_out'
    end

    it 'logs out user and redirects to main page', js: true do
      open_user_menu
      find('div.navbar ul li a#sign_out').click
      expect(current_path).to eq root_path
      user_should_not_be_logged_in
    end

    it 'shows account details link in the navbar', js: true do
      open_user_menu
      expect(page).to have_css 'div.navbar ul li a#my_account'
      find('div.navbar ul li a#my_account').click
      expect(current_path).to eq edit_user_registration_path
    end

    it 'does not show link to read view in user dropdown if user is already in read view', js: true do
      expect(current_path).to eq read_path
      expect(page).to_not have_css 'div.navbar ul li a#read_feeds'
    end

    it 'shows keyboard shortcuts help popup', js: true do
      expect(page).not_to have_css '#help-kb-shortcuts-popup', visible: true
      open_user_menu
      expect(page).to have_css 'div.navbar ul li a#help-kb-shortcuts'
      find('div.navbar ul li a#help-kb-shortcuts').click
      expect(page).to have_css '#help-kb-shortcuts-popup', visible: true
    end

    it 'shows help popup', js: true do
      expect(page).not_to have_css '#help-feedback-popup', visible: true
      open_user_menu
      expect(page).to have_css 'div.navbar ul li a#help'
      find('div.navbar ul li a#help').click
      expect(page).to have_css '#help-feedback-popup', visible: true
    end

    context 'edit profile' do

      before :each do
        visit edit_user_registration_path
      end

      it 'shows navbar', js: true do
        expect(page).to have_css 'div.navbar'
      end

      it 'shows link to go to feeds list', js: true do
        expect(page).to have_css 'a#return'
        find('a#return').click
        expect(current_path).to eq read_path
      end

      it 'shows link to read view in user dropdown', js: true do
        open_user_menu
        expect(page).to have_css 'div.navbar ul li a#read_feeds'
        find('a#read_feeds').click
        expect(current_path).to eq read_path
      end

      it 'allows email change', js: true do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        logout_user_for_feature

        # test that a confirmation email is sent
        confirmation_link = mail_should_be_sent path: confirmation_path, to: new_email
        # Convert the link sent by email into a relative URL that can be accessed during testing
        confirmation_url = get_confirm_address_link_from_email confirmation_link

        # test that before confirmation I can login with the old email
        login_user_for_feature @user
        logout_user_for_feature

        # test that after confirmation I cannot login with the old email
        visit confirmation_url
        failed_login_user_for_feature @user.email, @user.password

        # test that after confirmation I can login with the new email
        @user.email = new_email
        login_user_for_feature @user
      end

      it 'does not allow email change if current password is left blank', js: true do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        click_on 'Update account'
        logout_user_for_feature

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # test that I can login with the old email
        login_user_for_feature @user
      end

      it 'does not allow email change if current password is filled with wrong password', js: true do
        new_email = 'new_email@test.com'
        fill_in 'Email', with: new_email
        fill_in 'Current password', with: 'wrong_password'
        click_on 'Update account'
        logout_user_for_feature

        # test that a confirmation email is not sent
        mail_should_not_be_sent

        # test that I can login with the old email
        login_user_for_feature @user
        logout_user_for_feature
      end

      it 'allows password change', js: true do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: new_password
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        logout_user_for_feature

        # test that I cannot login with the old password
        failed_login_user_for_feature @user.email, @user.password

        # test that I can login with the new password
        @user.password = new_password
        login_user_for_feature @user
      end

      it 'does not allow password change if current password is left blank', js: true do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: new_password
        click_on 'Update account'
        logout_user_for_feature

        # test that I can login with the old password
        login_user_for_feature @user
      end

      it 'does not allow password change if current password is filled with wrong password', js: true do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: new_password
        fill_in 'Current password', with: 'wrong_password'
        click_on 'Update account'
        logout_user_for_feature

        # test that I can login with the old password
        login_user_for_feature @user
      end

      it 'does not allow password change if both password fields do not match', js: true do
        new_password = 'new_password'
        fill_in 'New password', with: new_password
        fill_in 'Password (again)', with: 'different_new_password'
        fill_in 'Current password', with: @user.password
        click_on 'Update account'
        logout_user_for_feature

        # test that I can login with the old password
        login_user_for_feature @user
      end

      it 'changes user language', js: true do
        # default language is english
        expect(page).to have_text 'Update account'

        # change to spanish
        fill_in 'Current password', with: @user.password
        select 'Español', from: 'Language'
        click_on 'Update account'
        expect(page).to have_text 'Mostrar leídos'
        logout_user_for_feature

        # After relogin, app should be in spanish
        login_user_for_feature @user
        expect(page).to have_text 'Bienvenido a FeedBunch'
      end

    end

    context 'delete account' do

      before :each do
        visit edit_user_registration_path
        page.find('#profile-cancel-button', text: 'Delete account').click
        # Wait for confirmation popup to appear
        expect(page).to have_css '#profile-delete-popup'
      end

      it 'does not allow deleting the account without entering a password', js: true do
        page.find('#profile-delete-submit').click
        # Popup should not be closed
        expect(page).to have_css '#profile-delete-popup', visible: true
      end

      it 'shows error message if wrong password is submitted', js: true do
        within '#profile-delete-popup' do
          fill_in 'Password', with: 'wrong password'
        end
        page.find('#profile-delete-submit').click
        expect(page).to have_text 'Invalid password'
        should_show_alert 'alert'
      end

      it 'enqueues job to delete account if correct password is submitted', js: true do
        expect(DestroyUserWorker.jobs.size).to eq 0

        within '#profile-delete-popup' do
          fill_in 'Password', with: @user.password
        end
        page.find('#profile-delete-submit').click
        expect(current_path).to eq root_path
        expect(page).to have_text 'Your account was successfully deleted'

        expect(DestroyUserWorker.jobs.size).to eq 1
        job = DestroyUserWorker.jobs.first
        expect(job['class']).to eq 'DestroyUserWorker'
        expect(job['args']).to eq [@user.id]
      end

      it 'prevents user from logging in again', js: true do
        within '#profile-delete-popup' do
          fill_in 'Password', with: @user.password
        end
        page.find('#profile-delete-submit').click
        expect(current_path).to eq root_path
        visit new_user_session_path
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: @user.password
        click_on 'Log in'
        expect(page).to have_text 'Invalid email or password'
      end
    end
  end
end