require 'rails_helper'

describe 'invite friend', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
    @friend_email = 'some_friends_email@domain.com'

    # TODO remove this line when friend invitation is opened to everyone
    @user.update admin: true

    login_user_for_feature @user
  end

  context 'send invitation' do

    # TODO remove this test when friend invitation is opened to everyone
    it 'non-admin users cannot send invitations', js: true do
      @user.update admin: false
      visit edit_user_registration_path
      expect(page).to have_no_css '#send-invitation-button', visible: true
    end


    it 'creates user and sends invitation email', js: true do
      expect(User.exists? email: @friend_email).to be false

      send_invitation @friend_email
      should_show_alert 'success-invite-friend'

      # test that an invitation email is sent
      mail_should_be_sent path: '/invitation', to: @friend_email, text: 'Someone has invited you'

      # User should be created
      expect(User.exists? email: @friend_email).to be true

      # Invited user should initially have the same locale and timezone as inviter. Username should
      # default to the email address.
      invited_user = User.find_by_email @friend_email
      expect(invited_user.name).to eq @friend_email
      expect(invited_user.locale).to eq @user.locale
      expect(invited_user.timezone).to eq @user.timezone

      # Invitations count for the inviter should be incremented by 1
      expect(@user.reload.invitations_count).to eq 1

      # Inviter and invited should be related
      expect(invited_user.invited_by).to eq @user
      expect(@user.invitations).to include invited_user
    end

    it 'cannot invite already confirmed user', js: true do
      existing_user = FactoryGirl.create :user, email: @friend_email

      send_invitation @friend_email
      should_show_alert 'problem-invited-user-exists'

      mail_should_not_be_sent
      # Existing user should not be modified
      expect(User.find_by_email @friend_email).to eq existing_user
      # Invitations count for the inviter should not be incremented
      expect(@user.reload.invitations_count).to eq 0
    end

    it 'cannot invite user who accepted an invitation', js: true do
      # friend receives and accepts an invitation
      send_invitation @friend_email
      logout_user
      expect(@user.reload.invitations_count).to eq 1
      accept_invitation invited_email: @friend_email
      logout_user
      invited_user = User.find_by_email @friend_email

      # send invitation again to the same friend
      login_user_for_feature @user
      send_invitation @friend_email
      should_show_alert 'problem-invited-user-exists'

      mail_should_not_be_sent
      # Existing user should not be modified
      expect(User.find_by_email @friend_email).to eq invited_user
      # Invitations count for the inviter should not be incremented
      expect(@user.reload.invitations_count).to eq 1
    end

    it 'resends invitation to already invited user', js: true do
      send_invitation @friend_email
      # Delete from the mail queue any email notifications sent when sending invitation
      ActionMailer::Base.deliveries.clear

      send_invitation @friend_email
      should_show_alert 'success-invitation-resend'

      # test that an invitation email is sent
      mail_should_be_sent path: '/invitation',
                          to: @friend_email, text: 'Someone has invited you'

      reinvited_user = User.find_by_email @friend_email

      # Invitations count for the inviter should be incremented by 1
      expect(@user.reload.invitations_count).to eq 2

      # Inviter and invited should be related
      expect(reinvited_user.invited_by).to eq @user
      expect(@user.invitations).to include reinvited_user
    end

    # TODO uncomment this test when the invite feature is opened to everyone
=begin
    it 'cannot send invitation if user has no invitations left', js: true do
      @user.update invitation_limit: 10, invitations_count: 10

      send_invitation @friend_email
      should_show_alert 'problem-no-invitations-left'

      mail_should_not_be_sent
      expect(User.exists? email: @friend_email).to be false
    end
=end

    it 'displays an alert if there is an error sending an invitation', js: true do
      allow(User).to receive(:exists?).and_raise StandardError.new
      send_invitation @friend_email
      should_show_alert 'problem-sending-invitation'
    end

    # TODO uncomment this test when beta ends and signup is opened to everyone
=begin
    it 'can sign up instead of accepting an invitation', js: true do
      # Friend is sent an invitation
      send_invitation @friend_email
      should_show_alert 'success-invite-friend'
      mail_should_be_sent path: '/invitation', to: @friend_email, text: 'Someone has invited you'
      logout_user

      friend_password = 'friend_password'
      sign_up @friend_email, friend_password

      friend = User.find_by_email @friend_email
      # Give value to password (instance attribute) so that user can Log in
      friend.password = friend_password
      login_user_for_feature friend
      user_should_be_logged_in
    end
=end

    # TODO uncomment this test when beta ends and signup is opened to everyone
=begin
    it 'cannot accept invitation after signing up', js: true do
      # Friend is sent an invitation
      send_invitation @friend_email
      should_show_alert 'success-invite-friend'
      accept_link = mail_should_be_sent path: '/invitation', to: @friend_email, text: 'Someone has invited you'
      logout_user

      # Friend signs up through the sign up view instead of clicking on the "accept invitation" link in the email
      visit new_user_registration_path
      friend_password = 'friend_password'
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: friend_password
      fill_in 'Confirm password', with: friend_password
      click_on 'Sign up'
      expect(current_path).to eq root_path

      # test that a confirmation email is sent
      confirmation_link = mail_should_be_sent path: confirmation_path, to: @friend_email

      # user should not be able to accept invitation after signup (before confirmation)
      accept_url = get_accept_invitation_link_from_email accept_link
      visit accept_url
      expect(page).to have_text 'The invitation token provided is not valid'

      # confirm email address entered during signup
      confirmation_url = get_confirm_address_link_from_email confirmation_link

      # user should not be able to accept invitation after signup (after confirmation)
      visit accept_url
      expect(page).to have_text 'The invitation token provided is not valid'
    end
=end

    # TODO uncomment this test when beta ends and signup is opened to everyone
=begin
    it 'does not destroy confirmed user when trying to sign up again', js: true do
      password = 'friend_password'
      existing_user = FactoryGirl.create :user, email: @friend_email, password: password
      logout_user

      expect_any_instance_of(User).not_to receive :destroy

      # existing user tries to sign up again
      visit new_user_registration_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: password
      fill_in 'Confirm password', with: password
      click_on 'Sign up'
      expect(page).to have_text 'Email has already been taken'
      expect(current_path).to eq new_user_registration_path
      # User instance should not have changed
      expect(User.find_by_email @friend_email).to eq existing_user
    end
=end

    # TODO uncomment this test when beta ends and signup is opened to everyone
=begin
    it 'does not destroy user who accepted an invitation when trying to sign up again', js: true do
      # User is sent and accepts invitation
      send_invitation @friend_email
      logout_user
      password = 'invited_password'
      accept_invitation password: password, invited_email: @friend_email
      logout_user
      invited_user = User.find_by_email @friend_email

      expect_any_instance_of(User).not_to receive :destroy

      # existing user tries to sign up again
      visit new_user_registration_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: password
      fill_in 'Confirm password', with: password
      click_on 'Sign up'
      expect(page).to have_text 'Email has already been taken'
      expect(current_path).to eq new_user_registration_path
      # User instance should not have changed
      expect(User.find_by_email @friend_email).to eq invited_user
    end
=end

  end

  context 'accept invitation' do

    before :each do
      send_invitation @friend_email
      logout_user
      @accept_link = mail_should_be_sent path: '/invitation',
                                         to: @friend_email, text: 'Someone has invited you'

      # Build the correct URL that must be used in testing for accepting invitations
      @accept_url = get_accept_invitation_link_from_email @accept_link

      @password = 'invited_password'
    end

    it 'cannot accept invitation with wrong token', js: true do
      url = URI accept_user_invitation_path
      url.query = 'invitation_token=wrong_token'
      visit url
      expect(page).to have_text 'The invitation token provided is not valid'
    end

    it 'cannot log in before accepting invitation', js: true do
      visit new_user_session_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: @password
      click_on 'Log in'

      user_should_not_be_logged_in
    end

    it 'accepts invitation', js: true do
      visit @accept_url
      fill_in 'Password', with: @password
      fill_in 'Confirm password', with: @password
      click_on 'Activate account'

      # User should be immediately logged in
      expect(current_path).to eq read_path
      user_should_be_logged_in

      # User should be able to log in with the chosen password
      logout_user
      visit new_user_session_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: @password
      click_on 'Log in'

      user_should_be_logged_in
    end

    it 'accepts invitation from resent invitation email', js: true do
      login_user_for_feature @user
      # Send second invitation
      send_invitation @friend_email
      should_show_alert 'success-invitation-resend'
      logout_user

      # Link in second invitation should be the same as in the first
      resent_link = mail_should_be_sent path: '/invitation',
                                        to: @friend_email, text: 'Someone has invited you'
      resent_accept_url = get_accept_invitation_link_from_email resent_link

      expect(resent_accept_url).to eq @accept_url

      # Accept invitation from second email
      visit resent_accept_url
      fill_in 'Password', with: @password
      fill_in 'Confirm password', with: @password
      click_on 'Activate account'

      # User should be immediately logged in
      expect(current_path).to eq read_path
      user_should_be_logged_in

      # User should be able to log in with the chosen password
      logout_user
      visit new_user_session_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: @password
      click_on 'Log in'

      user_should_be_logged_in
    end

    # TODO uncomment this test when beta ends and signup is opened to everyone
=begin
    it 'cannot sign up after accepting invitation', js: true do
      accept_invitation password: @password, accept_link: @accept_link, invited_email: @friend_email
      logout_user

      invited_user = User.find_by_email @friend_email

      # User should not be destroyed when trying to sign up
      expect_any_instance_of(User).not_to receive :destroy

      visit new_user_registration_path
      fill_in 'Email', with: @friend_email
      fill_in 'Password', with: @password
      fill_in 'Confirm password', with: @password
      click_on 'Sign up'

      expect(page).to have_text 'Email has already been taken'
      # User should not be changed by this signup attempt
      expect(User.find_by_email @friend_email).to eq invited_user
    end
=end

  end

end