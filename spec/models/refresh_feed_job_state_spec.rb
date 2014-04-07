require 'spec_helper'

describe RefreshFeedJobState do

  context 'validations' do

    it 'always belongs to a user' do
      refresh_feed_job_state = FactoryGirl.build :refresh_feed_job_state, user_id: nil
      refresh_feed_job_state.should_not be_valid
    end

    it 'always belongs to a feed' do
      refresh_feed_job_state = FactoryGirl.build :refresh_feed_job_state, feed_id: nil
      refresh_feed_job_state.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to state RUNNING when created' do
      refresh_feed_job_state = FactoryGirl.create :refresh_feed_job_state
      refresh_feed_job_state.state.should eq RefreshFeedJobState::RUNNING
    end

  end

end
