# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryBot.create :user
  end

  context 'delete user profile' do

    it 'enqueues a job to destroy the user' do
      expect(DestroyUserWorker.jobs.size).to eq 0

      @user.delete_profile

      expect(DestroyUserWorker.jobs.size).to eq 1
      job = DestroyUserWorker.jobs.first
      expect(job['class']).to eq 'DestroyUserWorker'
      expect(job['args']).to eq [@user.id]
    end

    it 'locks user account immediately' do
      expect(@user).to receive(:lock_access!).with send_instructions: false
      @user.delete_profile
    end

    it 'does nothing if the user is the demo user' do
      Feedbunch::Application.config.demo_enabled = true
      demo_email = 'demo@feedbunch.com'
      Feedbunch::Application.config.demo_email = demo_email

      demo_password = 'feedbunch-demo'
      Feedbunch::Application.config.demo_password = demo_password

      demo_user = FactoryBot.create :user,
                                      email: demo_email,
                                      password: demo_password,
                                      confirmed_at: Time.zone.now

      # Demo user will not be locked
      expect(@user).not_to receive :lock_access!

      demo_user.delete_profile

      # Destroy worker not enqueued
      expect(DestroyUserWorker.jobs.size).to eq 0
    end
  end

end
