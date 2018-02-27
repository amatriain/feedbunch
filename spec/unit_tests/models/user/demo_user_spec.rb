require 'rails_helper'

describe User, type: :model do

  context 'demo user' do

    before :each do
      @demo_email = 'demo@feedbunch.com'
      Feedbunch::Application.config.demo_email = @demo_email

      @demo_password = 'feedbunch-demo'
      Feedbunch::Application.config.demo_password = @demo_password

      @demo_user = FactoryBot.create :user,
                                      email: @demo_email,
                                      password: @demo_password,
                                      confirmed_at: Time.zone.now
    end

    context 'demo disabled' do

      before :each do
        Feedbunch::Application.config.demo_enabled = false
      end

      it 'can change demo email' do
        @demo_user.update email: 'another@email.com'
        expect(@demo_user.reload.unconfirmed_email).to eq 'another@email.com'
      end

      it 'can change demo password' do
        encrypted_password = @demo_user.encrypted_password
        @demo_user.update password: 'another_password'
        expect(@demo_user.reload.encrypted_password).not_to eq encrypted_password
      end

      it 'can lock demo user' do
        expect(@demo_user.locked_at).to be nil
        @demo_user.update locked_at: Time.zone.now, unlock_token: 'aaabbbccc'
        expect(@demo_user.locked_at).not_to be nil
        expect(@demo_user.unlock_token).not_to be nil
      end

      it 'can destroy demo user' do
        @demo_user.destroy
        expect(User.exists? email: @demo_email).to be false
      end
    end

    context 'demo enabled' do

      before :each do
        Feedbunch::Application.config.demo_enabled = true
      end

      it 'cannot change demo user email' do
        @demo_user.update email: 'another@email.com'
        expect(@demo_user.reload.email).to eq Feedbunch::Application.config.demo_email
        expect(@demo_user.unconfirmed_email).to be nil
      end

      it 'can change email of other users' do
        user = FactoryBot.create :user
        expect(user.email).not_to eq @demo_email

        user.update email: 'another@email.com'
        expect(user.reload.unconfirmed_email).to eq 'another@email.com'
      end

      it 'cannot change demo user password' do
        @demo_user.update password: 'another_password'
        expect(@demo_user.reload.password).to eq @demo_password
      end

      it 'can change password of other users' do
        user = FactoryBot.create :user
        encrypted_password = user.encrypted_password
        encrypted_demo_password = @demo_user.encrypted_password
        expect(encrypted_password).not_to eq encrypted_demo_password

        user.update password: 'another_password'
        expect(user.reload.encrypted_password).not_to eq encrypted_password
      end

      it 'cannot lock demo user' do
        @demo_user.update locked_at: Time.zone.now, unlock_token: 'aaabbbccc'
        expect(@demo_user.reload.locked_at).to be nil
        expect(@demo_user.unlock_token).to be nil
      end

      it 'can lock other users' do
        user = FactoryBot.create :user
        expect(user.locked_at).to be nil

        user.update locked_at: Time.zone.now, unlock_token: 'aaabbbccc'
        expect(user.reload.locked_at).not_to be nil
        expect(user.unlock_token).not_to be nil
      end

      it 'cannot destroy demo user' do
        @demo_user.destroy
        expect(User.exists? email: @demo_email).to be true
      end

    end
  end
end
