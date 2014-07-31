require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user

    friend_email = 'some_friend@email.com'
    friend_name = 'some friend'
    invitation_params = {email: friend_email,
                         name: friend_name,
                         locale: @user.locale,
                         timezone: @user.timezone}
    @invited_user = User.invite! invitation_params, @user
  end

  context 'user invitations' do

    it 'defaults to the currently configured daily limit' do
      limit = Feedbunch::Application.config.daily_invitations_limit

      user = FactoryGirl.create :user
      expect(user.invitation_limit).to eq limit

      user2 = FactoryGirl.create :user, invitation_limit: nil
      expect(user2.invitation_limit).to eq limit
    end

    it 'returns user who invited a given user' do
      expect(@invited_user.invited_by).to eq @user
    end

    it 'returns users invited by a user' do
      expect(@user.invitations).to include @invited_user
    end

    it 'does not destroy inviter when destroying an invited user' do
      expect(User.exists? @user.id).to be true
      @invited_user.destroy!
      expect(User.exists? @user.id).to be true
    end

    it 'does not return invited user after destroying it' do
      @invited_user.destroy!
      expect(@user.reload.invitations).to be_empty
    end

    it 'does not destroy invited when destroying the inviter user' do
      expect(User.exists? @invited_user.id).to be true
      @user.destroy!
      expect(User.exists? @invited_user.id).to be true
    end

    it 'does not return inviter after destroying it' do
      @user.destroy!
      expect(@invited_user.reload.invited_by).to be nil
    end
  end
end
