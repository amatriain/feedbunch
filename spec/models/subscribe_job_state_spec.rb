require 'spec_helper'

describe SubscribeJobState do

  context 'validations' do

    it 'always belongs to a user' do
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, user_id: nil
      subscribe_job_state.should_not be_valid
    end

    it 'always belongs has a fetch_url' do
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, fetch_url: nil
      subscribe_job_state.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to state RUNNING when created' do
      subscribe_job_state = FactoryGirl.create :subscribe_job_state
      subscribe_job_state.state.should eq RefreshFeedJobState::RUNNING
    end

  end

end
