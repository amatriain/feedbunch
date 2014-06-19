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
    it 'does not send invitation for non-admin users', js: true do
      @user.update admin: false
      send_invitation @friend_email

      should_show_alert 'problem-invite-friend-unauthorized'
      mail_should_not_be_sent
      expect(User.exists? email: @friend_email).to be false
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
      # Inviter and invited should be related
      expect(invited_user.invited_by).to eq @user
    end

  end

  context 'accept invitation' do

  end

end