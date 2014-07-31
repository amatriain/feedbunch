require 'rails_helper'

describe CleanupInvitationsJob do

  before :each do
    @user = FactoryGirl.create :user

    # During the tests, Time.zone.now will always return "2001-01-01 10:00:00"
    @time_now = Time.zone.parse('2000-01-01 10:00:00')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now
  end

  context 'discard old unaccepted invitations' do

    before :each do
discard_unaccepted_invitations_after = Feedbunch::Application.config.discard_unaccepted_invitations_after
      # Unaccepted invitations sent before this time are considered "old" and will be destroyed.
      @time_invitations_old = @time_now - discard_unaccepted_invitations_after

      @friend_email_1 = 'some_friend_1@email.com'
      @friend_email_2 = 'some_friend_2@email.com'
      @friend_name_1 = 'some friend_1'
      @friend_name_2 = 'some friend_2'
    end

    it 'destroys old unaccepted invitations' do
      invitation_params_1 = {email: @friend_email_1,
                           name: @friend_name_1,
                           locale: @user.locale,
                           timezone: @user.timezone}
      old_unaccepted_invitation_1 = User.invite! invitation_params_1, @user

      invitation_params_2 = {email: @friend_email_2,
                             name: @friend_name_2,
                             locale: @user.locale,
                             timezone: @user.timezone}
      old_unaccepted_invitation_2 = User.invite! invitation_params_2, @user

      time_invitation_sent = @time_invitations_old - 1.day
      # invitations are 1 day older than the interval to be considered for discarding
      old_unaccepted_invitation_1.update invitation_created_at: time_invitation_sent,
                                       invitation_sent_at: time_invitation_sent
      old_unaccepted_invitation_2.update invitation_created_at: time_invitation_sent,
                                         invitation_sent_at: time_invitation_sent

      expect(User.exists? old_unaccepted_invitation_1.id).to be true
      expect(User.exists? old_unaccepted_invitation_2.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? old_unaccepted_invitation_1.id).to be false
      expect(User.exists? old_unaccepted_invitation_2.id).to be false
    end

    it 'does not destroy newer unaccepted invitations' do
      invitation_params_1 = {email: @friend_email_1,
                             name: @friend_name_1,
                             locale: @user.locale,
                             timezone: @user.timezone}
      new_unaccepted_invitation_1 = User.invite! invitation_params_1, @user

      invitation_params_2 = {email: @friend_email_2,
                             name: @friend_name_2,
                             locale: @user.locale,
                             timezone: @user.timezone}
      new_unaccepted_invitation_2 = User.invite! invitation_params_2, @user

      time_invitation_sent = @time_invitations_old + 1.day
      # invitations are 1 day newer than the interval to be considered for discarding
      new_unaccepted_invitation_1.update invitation_created_at: time_invitation_sent,
                                         invitation_sent_at: time_invitation_sent
      new_unaccepted_invitation_2.update invitation_created_at: time_invitation_sent,
                                         invitation_sent_at: time_invitation_sent

      expect(User.exists? new_unaccepted_invitation_1.id).to be true
      expect(User.exists? new_unaccepted_invitation_2.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? new_unaccepted_invitation_1.id).to be true
      expect(User.exists? new_unaccepted_invitation_2.id).to be true
    end

    it 'does not destroy old accepted invitations' do
      invitation_params_1 = {email: @friend_email_1,
                             name: @friend_name_1,
                             locale: @user.locale,
                             timezone: @user.timezone}
      old_accepted_invitation_1 = User.invite! invitation_params_1, @user

      invitation_params_2 = {email: @friend_email_2,
                             name: @friend_name_2,
                             locale: @user.locale,
                             timezone: @user.timezone}
      old_accepted_invitation_2 = User.invite! invitation_params_2, @user

      time_invitation_sent = @time_invitations_old - 1.day
      # invitations are 1 day older than the interval to be considered for discarding
      old_accepted_invitation_1.update invitation_created_at: time_invitation_sent,
                                         invitation_sent_at: time_invitation_sent
      old_accepted_invitation_2.update invitation_created_at: time_invitation_sent,
                                         invitation_sent_at: time_invitation_sent

      # accept invitations
      old_accepted_invitation_1.accept_invitation!
      old_accepted_invitation_2.accept_invitation!

      expect(User.exists? old_accepted_invitation_1.id).to be true
      expect(User.exists? old_accepted_invitation_2.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? old_accepted_invitation_1.id).to be true
      expect(User.exists? old_accepted_invitation_2.id).to be true
    end

    it 'does not destroy newer accepted invitations' do
      invitation_params_1 = {email: @friend_email_1,
                             name: @friend_name_1,
                             locale: @user.locale,
                             timezone: @user.timezone}
      new_accepted_invitation_1 = User.invite! invitation_params_1, @user

      invitation_params_2 = {email: @friend_email_2,
                             name: @friend_name_2,
                             locale: @user.locale,
                             timezone: @user.timezone}
      new_accepted_invitation_2 = User.invite! invitation_params_2, @user

      time_invitation_sent = @time_invitations_old + 1.day
      # invitations are 1 day newer than the interval to be considered for discarding
      new_accepted_invitation_1.update invitation_created_at: time_invitation_sent,
                                       invitation_sent_at: time_invitation_sent
      new_accepted_invitation_2.update invitation_created_at: time_invitation_sent,
                                       invitation_sent_at: time_invitation_sent

      # accept invitations
      new_accepted_invitation_1.accept_invitation!
      new_accepted_invitation_2.accept_invitation!

      expect(User.exists? new_accepted_invitation_1.id).to be true
      expect(User.exists? new_accepted_invitation_2.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? new_accepted_invitation_1.id).to be true
      expect(User.exists? new_accepted_invitation_2.id).to be true
    end

    it 'does not destroy users who signed up instead of being invited' do
      time_new_signup = @time_invitations_old + 1.day
      new_user = FactoryGirl.create :user, created_at:  time_new_signup,
                                    confirmed_at: time_new_signup,
                                    confirmation_sent_at: time_new_signup
      time_old_signup = @time_invitations_old - 1.day
      old_user = FactoryGirl.create :user, created_at:  time_old_signup,
                                    confirmed_at: time_old_signup,
                                    confirmation_sent_at: time_old_signup

      expect(User.exists? new_user.id).to be true
      expect(User.exists? old_user.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? new_user.id).to be true
      expect(User.exists? old_user.id).to be true
    end

    it 'does not destroy users who signed up but did not confirm their email address' do
      time_new_signup = @time_invitations_old + 1.day
      new_user = FactoryGirl.create :user, created_at:  time_new_signup,
                                    confirmed_at: nil,
                                    confirmation_sent_at: time_new_signup
      time_old_signup = @time_invitations_old - 1.day
      old_user = FactoryGirl.create :user, created_at:  time_old_signup,
                                    confirmed_at: nil,
                                    confirmation_sent_at: time_old_signup

      expect(User.exists? new_user.id).to be true
      expect(User.exists? old_user.id).to be true

      CleanupInvitationsJob.perform

      expect(User.exists? new_user.id).to be true
      expect(User.exists? old_user.id).to be true
    end
  end

  context 'reset daily invitations limit' do

    before :each do
      @daily_invitations_limit = Feedbunch::Application.config.daily_invitations_limit
    end

    it 'sets invitation limit for users that do not have it' do
      @user.update invitation_limit: nil

      CleanupInvitationsJob.perform

      expect(@user.reload.invitation_limit).to eq @daily_invitations_limit
    end

    it 'sets invitation limit for users that have the wrong limit' do
      @user.update invitation_limit: @daily_invitations_limit - 1

      CleanupInvitationsJob.perform

      expect(@user.reload.invitation_limit).to eq @daily_invitations_limit
    end
  end

end
