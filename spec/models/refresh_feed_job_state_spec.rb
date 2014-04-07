require 'spec_helper'

describe RefreshFeedJobState do

  context 'validations' do

    it 'always belongs to a user' do
      refresh_feed_job_status = FactoryGirl.build :refresh_feed_job_status, user_id: nil
      refresh_feed_job_status.should_not be_valid
    end

    it 'always belongs to a feed' do
      refresh_feed_job_status = FactoryGirl.build :refresh_feed_job_status, feed_id: nil
      refresh_feed_job_status.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to status RUNNING when created' do
      refresh_feed_job_status = FactoryGirl.create :refresh_feed_job_status
      refresh_feed_job_status.status.should eq RefreshFeedJobState::RUNNING
    end

  end

end
