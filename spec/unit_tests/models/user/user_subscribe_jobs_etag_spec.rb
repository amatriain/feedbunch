require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @old_subscribe_jobs_etag = @user.reload.subscribe_jobs_etag
  end

  context 'touches subscribe jobs' do

    it 'when a job state is created' do
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id
      @user.subscribe_job_states << job_state
      expect(@user.reload.subscribe_jobs_etag).not_to eq @old_subscribe_jobs_etag
    end

    it 'when a job state is destroyed' do
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id
      @user.subscribe_job_states << job_state
      @old_subscribe_jobs_etag = @user.reload.subscribe_jobs_etag

      job_state.destroy
      expect(@user.reload.subscribe_jobs_etag).not_to eq @old_subscribe_jobs_etag
    end

    it 'when a job state is updated' do
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id
      @user.subscribe_job_states << job_state
      @old_subscribe_jobs_etag = @user.reload.subscribe_jobs_etag

      job_state.update state: SubscribeJobState::ERROR
      expect(@user.reload.subscribe_jobs_etag).not_to eq @old_subscribe_jobs_etag
    end
  end
end