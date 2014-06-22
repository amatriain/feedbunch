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
      expect(page).not_to have_css '#send-invitation-button', visible: true
    end


    it 'creates user and sends invitation email', js: true do
      expect(User.exists? email: @friend_email).to be false

      send_invitation @friend_email
      should_show_alert 'success-invite-friend'

      # test that an invitation email is sent
      mail_should_be_sent path: '/accept_invitation', to: @friend_email, text: 'Someone has invited you'

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

    it 'resends invitation to already invited user', js: true do
      send_invitation @friend_email
      # Delete from the mail queue any email notifications sent when sending invitation
      ActionMailer::Base.deliveries.clear

      send_invitation @friend_email
      should_show_alert 'success-invitation-resend'

      # test that an invitation email is sent
      mail_should_be_sent path: '/accept_invitation',
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

  end

  context 'accept invitation' do

    before :each do
      send_invitation @friend_email
      logout_user
      @accept_link = mail_should_be_sent path: '/accept_invitation',
                                         to: @friend_email, text: 'Someone has invited you'
    end

    it 'accepts invitation', js: true do
      visit @accept_link
    end

  end

end