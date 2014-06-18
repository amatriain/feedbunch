require 'rails_helper'

describe Devise::FriendInvitationsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user, admin: true
    @friend_email = 'friends.will.be.friends@righttotheend.com'
    login_user_for_unit @user
  end

  context 'POST create' do

    it 'returns success' do
      post :create, user: {email: @friend_email}, format: :json
      expect(response).to be_success
    end

    it 'returns 403 if user is not an admin' do
      @user.update admin: false
      post :create, user: {email: @friend_email}, format: :json
      expect(response.status).to eq 403
    end

    it 'invites user with the passed email' do
      post :create, user: {email: @friend_email}, format: :json
      expect(assigns(:invited_user).email).to eq @friend_email
      expect(assigns(:invited_user).name).to eq @friend_email
      mail_should_be_sent path: '/accept_invitation', to: @friend_email, text: 'Someone has invited you'
    end

    it 'initially assigns the inviter locale and timezone to the invited' do
      @user.update locale: 'en', timezone: 'UTC'
      post :create, user: {email: @friend_email}, format: :json
      invited = User.find_by_email @friend_email
      expect(invited.locale).to eq 'en'
      expect(invited.timezone).to eq 'UTC'

      @user.update locale: 'es', timezone: 'Madrid'
      post :create, user: {email: @friend_email}, format: :json
      invited = User.find_by_email @friend_email
      expect(invited.locale).to eq 'es'
      expect(invited.timezone).to eq 'Europe/Madrid'
    end
  end
end
