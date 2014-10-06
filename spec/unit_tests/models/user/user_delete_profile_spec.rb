require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
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
  end

end
