require 'rails_helper'

describe CleanupSignupsWorker do

  before :each do
    # During the tests, Time.zone.now will always return "2001-01-01 10:00:00"
    @time_now = Time.zone.parse('2000-01-01 10:00:00')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now

    discard_unconfirmed_signups_after = Feedbunch::Application.config.discard_unconfirmed_signups_after
    # Unconfirmed signups sent before this time are considered "old" and will be destroyed.
    @time_signups_old = @time_now - discard_unconfirmed_signups_after

    # @user is an unconfirmed user. The confirmation_sent_at date will be different for different tests.
    @user = FactoryGirl.create :user, confirmed_at: nil
  end

  context 'discard old unconfirmed signups' do

    it 'destroys old unconfirmed signups' do
      time_signup = @time_signups_old - 1.day
      # signup is 1 day older than the interval to be considered for discarding
      @user.update confirmation_sent_at: time_signup

      expect(User.exists? @user.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? @user.id).to be false
    end

    it 'does not destroy newer unconfirmed signups' do
      time_signup = @time_signups_old + 1.day
      # signup is 1 day newer than the interval to be considered for discarding
      @user.update confirmation_sent_at: time_signup

      expect(User.exists? @user.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? @user.id).to be true
    end

    it 'does not destroy old confirmed signups' do
      time_signup = @time_signups_old - 1.day
      # signup is 1 day older than the interval to be considered for discarding
      @user.update confirmation_sent_at: time_signup,
                   confirmed_at: time_signup

      expect(User.exists? @user.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? @user.id).to be true
    end

    it 'does not destroy newer confirmed signups' do
      time_signup = @time_signups_old + 1.day
      # signup is 1 day newer than the interval to be considered for discarding
      @user.update confirmation_sent_at: time_signup,
                   confirmed_at: time_signup

      expect(User.exists? @user.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? @user.id).to be true
    end

    it 'does not destroy users who were sent an invitation' do
      invitation_params_old = {email: 'friend_1@email.com',
                             name: 'friend_1',
                             locale: @user.locale,
                             timezone: @user.timezone}
      old_accepted_invitation = User.invite! invitation_params_old, @user
      time_invitation_old = @time_signups_old - 1.day
      old_accepted_invitation.update invitation_created_at: time_invitation_old,
                                     invitation_sent_at: time_invitation_old,
                                     invitation_accepted_at: nil,
                                     confirmed_at: nil

      invitation_params_new = {email: 'friend_2@email.com',
                               name: 'friend_2',
                               locale: @user.locale,
                               timezone: @user.timezone}
      new_accepted_invitation = User.invite! invitation_params_new, @user
      time_invitation_new = @time_signups_old + 1.day
      new_accepted_invitation.update invitation_created_at: time_invitation_new,
                                     invitation_sent_at: time_invitation_new,
                                     invitation_accepted_at: nil,
                                     confirmed_at: nil

      expect(User.exists? old_accepted_invitation.id).to be true
      expect(User.exists? new_accepted_invitation.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? old_accepted_invitation.id).to be true
      expect(User.exists? new_accepted_invitation.id).to be true
    end

    it 'does not destroy users who accepted an invitation' do
      invitation_params_old = {email: 'friend_1@email.com',
                               name: 'friend_1',
                               locale: @user.locale,
                               timezone: @user.timezone}
      old_accepted_invitation = User.invite! invitation_params_old, @user
      time_invitation_old = @time_signups_old - 1.day
      old_accepted_invitation.update invitation_created_at: time_invitation_old,
                                     invitation_sent_at: time_invitation_old,
                                     invitation_accepted_at: time_invitation_old,
                                     confirmed_at: time_invitation_old

      invitation_params_new = {email: 'friend_2@email.com',
                               name: 'friend_2',
                               locale: @user.locale,
                               timezone: @user.timezone}
      new_accepted_invitation = User.invite! invitation_params_new, @user
      time_invitation_new = @time_signups_old + 1.day
      new_accepted_invitation.update invitation_created_at: time_invitation_new,
                                     invitation_sent_at: time_invitation_new,
                                     invitation_accepted_at: time_invitation_new,
                                     confirmed_at: time_invitation_new

      expect(User.exists? old_accepted_invitation.id).to be true
      expect(User.exists? new_accepted_invitation.id).to be true

      CleanupSignupsWorker.new.perform

      expect(User.exists? old_accepted_invitation.id).to be true
      expect(User.exists? new_accepted_invitation.id).to be true
    end
  end

end
