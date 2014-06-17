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
  end
end
