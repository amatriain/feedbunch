require 'rails_helper'

describe FeedbunchAuth::InvitationsController, type: :controller do

  before :each do
    # TODO remove admin: true when the invite feature is opened to everyone
    @user = FactoryGirl.create :user, admin: true
    @friend_email = 'friends.will.be.friends@righttotheend.com'
    login_user_for_unit @user
  end

  context 'POST create' do

    context 'validations' do

      # TODO delete this test when the invite feature is opened to everyone
      it 'returns 403 if user is not an admin' do
        @user.update admin: false
        post :create, user: {email: @friend_email}, format: :json
        expect(response.status).to eq 403
      end

      it 'returns 409 if user already exists and has not been invited' do
        user2 = FactoryGirl.create :user, email: @friend_email
        post :create, user: {email: @friend_email}, format: :json
        expect(response.status).to eq 409
      end

      # TODO uncomment these tests when the invite feature is opened to everyone
=begin
      it 'returns 400 if user has no invitations left' do
        @user.update invitation_limit: 10, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response.status).to eq 400
      end

      it 'returns success regardless of invitations sent if no invitations limit is set' do
        @user.update invitation_limit: nil, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response).to be_success
      end
=end

      it 'returns success regardless of invitations limit if user is an admin' do
        @user.update admin: true, invitation_limit: 10, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response).to be_success
      end

    end

    context 'successful invitation' do

      it 'returns success' do
        post :create, user: {email: @friend_email}, format: :json
        expect(response).to be_success
      end

      it 'invites user with the passed email' do
        invitations_before = @user.invitations_count

        post :create, user: {email: @friend_email}, format: :json

        expect(assigns(:invited_user).email).to eq @friend_email
        expect(assigns(:invited_user).name).to eq @friend_email
        mail_should_be_sent path: '/accept_invitation', to: @friend_email, text: 'Someone has invited you'

        # Inviter's invitations count should increase by 1
        expect(@user.reload.invitations_count).to eq invitations_before + 1
      end

      it 'initially assigns the inviter locale and timezone to the invited' do
        @user.update locale: 'en', timezone: 'UTC'

        post :create, user: {email: @friend_email}, format: :json

        invited = User.find_by_email @friend_email
        expect(invited.locale).to eq 'en'
        expect(invited.timezone).to eq 'UTC'

        User.find_by_email(@friend_email).destroy
        sign_out @user
        @user.update locale: 'es', timezone: 'Madrid'
        login_user_for_unit @user

        post :create, user: {email: @friend_email}, format: :json

        invited = User.find_by_email @friend_email
        expect(invited.locale).to eq 'es'
        expect(invited.timezone).to eq 'Madrid'
      end
    end

    context 'already invited user' do

      before :each do
        @date_now = Time.zone.parse '2000-01-01'
        @invitation_token = 'abc'
        @unencrypted_invitation_token = 'def'
        @invited_user = FactoryGirl.create :user, email: @friend_email,
                                          confirmed_at: nil, invitation_token: @invitation_token,
                                          unencrypted_invitation_token: @unencrypted_invitation_token,
                                          invitation_created_at: @date_now, invitation_sent_at: @date_now
        # Delete from the mail queue any email notifications sent when creating @invited_user
        ActionMailer::Base.deliveries.clear
      end

      it 'returns 202 and resends invitation if user is already invited and unconfirmed' do
        invitations_before = @user.invitations_count

        post :create, user: {email: @friend_email}, format: :json

        # Returns HTTP 202
        expect(response.status).to eq 202
        # No new user should be created
        expect(User.find_by_email @friend_email).to eq @invited_user
        # Invitation token should not change
        expect(@invited_user.reload.invitation_token).to eq @invitation_token
        # Invitation email should be sent again
        mail_should_be_sent path: "/accept_invitation?invitation_token=#{@unencrypted_invitation_token}",
                            to: @friend_email,
                            text: 'Someone has invited you'
        # Inviter's invitations count should increase by 1
        expect(@user.reload.invitations_count).to eq invitations_before + 1
      end

      # TODO uncomment these tests when the invite feature is opened to everyone
=begin
      it 'does not resend invitation if inviter has no invitations left' do
        @user.update invitation_limit: 10, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response.status).to eq 400
        mail_should_not_be_sent
        expect(@user.reload.invitations_count).to eq 10
      end

    it 'returns success regardless of invitations sent if no invitations limit is set' do
        @user.update invitation_limit: nil, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response.status).to eq 202
      end

      it 'resends invitation regardless of invitations limit if user is an admin' do
        @user.update admin: true, invitation_limit: 10, invitations_count: 10

        post :create, user: {email: @friend_email}, format: :json

        expect(response.status).to eq 202
      end
=end

    end

  end
end
