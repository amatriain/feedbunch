require 'spec_helper'

describe RefreshFeedJob do

  context 'validations' do

    it 'always belongs to a user' do
      refresh_feed_job = FactoryGirl.build :refresh_feed_job, user_id: nil
      refresh_feed_job.should_not be_valid
    end

    it 'always belongs to a feed' do
      refresh_feed_job = FactoryGirl.build :refresh_feed_job, feed_id: nil
      refresh_feed_job.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to status RUNNING when created' do
      refresh_feed_job = FactoryGirl.create :refresh_feed_job
      refresh_feed_job.status.should eq RefreshFeedJob::RUNNING
    end

  end

end
