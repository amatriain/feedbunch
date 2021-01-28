# frozen_string_literal: true

require 'rails_helper'

describe CleanupSignupsWorker do

  before :each do
    # During the tests, Time.zone.now will always return "2001-01-01 10:00:00"
    @time_now = Time.zone.parse('2000-01-01 10:00:00')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now

    # @user is an unconfirmed user. The confirmation_sent_at date will be different for different tests.
    @user = FactoryBot.create :user, confirmed_at: nil
  end

  context 'discard old unconfirmed signups' do

    before :each do
      discard_unconfirmed_signups_after = Feedbunch::Application.config.discard_unconfirmed_signups_after
      # Unconfirmed signups from before this time are considered "old" and will be destroyed.
      @time_signups_old = @time_now - discard_unconfirmed_signups_after
    end

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
  end

  context 'confirmation reminder emails' do

    context 'first reminder email' do

      before :each do
        first_confirmation_reminder_after = Feedbunch::Application.config.first_confirmation_reminder_after
        # Unconfirmed signups from before this time will be sent a reminder email
        @time_first_confirmation_reminder = @time_now - first_confirmation_reminder_after
      end

      it 'sends reminder to old unconfirmed signups' do
        time_signup = @time_first_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup
        expect(@user.reload.first_confirmation_reminder_sent).to be false

        CleanupSignupsWorker.new.perform

        mail_should_be_sent 'Please confirm your email address', path: '/resend_confirmation', to: @user.email
        expect(@user.reload.first_confirmation_reminder_sent).to be true
      end

      it 'does not send reminder to newer signups' do
        time_signup = @time_first_confirmation_reminder + 1.hour
        # signup is 1 hour newer than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear

        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end

      it 'does not send this reminder a second time' do
        time_signup = @time_first_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup

        CleanupSignupsWorker.new.perform
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear
        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end

      it 'does not send reminder to confirmed users' do
        time_signup = @time_first_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup, confirmed_at: Time.zone.now
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear

        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end
    end

    context 'second reminder email' do

      before :each do
        second_confirmation_reminder_after = Feedbunch::Application.config.second_confirmation_reminder_after
        # Unconfirmed signups from before this time will be sent a reminder email
        @time_second_confirmation_reminder = @time_now - second_confirmation_reminder_after
        # User has already been sent the first reminder, we're testing the second reminder here
        @user.update first_confirmation_reminder_sent: true
      end

      it 'sends reminder to old unconfirmed signups' do
        time_signup = @time_second_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup
        expect(@user.reload.second_confirmation_reminder_sent).to be false

        CleanupSignupsWorker.new.perform

        mail_should_be_sent 'Please confirm your email address', path: '/resend_confirmation', to: @user.email
        expect(@user.reload.second_confirmation_reminder_sent).to be true
      end

      it 'does not send reminder to newer signups' do
        time_signup = @time_second_confirmation_reminder + 1.hour
        # signup is 1 hour newer than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear

        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end

      it 'does not send this reminder a second time' do
        time_signup = @time_second_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup

        CleanupSignupsWorker.new.perform
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear
        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end

      it 'does not send reminder to confirmed users' do
        time_signup = @time_second_confirmation_reminder - 1.hour
        # signup is 1 hour older than the interval to be considered for sending a reminder
        @user.update confirmation_sent_at: time_signup, confirmed_at: Time.zone.now
        # Clear the email delivery queue
        ActionMailer::Base.deliveries.clear

        CleanupSignupsWorker.new.perform

        mail_should_not_be_sent
      end

    end
  end
end
