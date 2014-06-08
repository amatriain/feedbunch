require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'delete user profile' do

    it 'enqueues a job to destroy the user' do
      expect(Resque).to receive(:enqueue) do |job_class, user_id|
        expect(job_class).to eq DestroyUserJob
        expect(user_id).to eq @user.id
      end
      @user.delete_profile
    end

    it 'locks user account immediately' do
      expect(@user).to receive(:lock_access!).with send_instructions: false
      @user.delete_profile
    end
  end

end
