require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'delete user profile' do

    it 'enqueues a job to destroy the user' do
      Resque.should_receive(:enqueue) do |job_class, user_id|
        job_class.should eq DestroyUserJob
        user_id.should eq @user.id
      end
      @user.delete_profile
    end

    it 'locks user account immediately' do
      @user.should_receive(:lock_access!).with send_instructions: false
      @user.delete_profile
    end
  end

end
