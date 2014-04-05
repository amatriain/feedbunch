require 'spec_helper'

describe User do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'enqueues a job to update the feed' do
    Resque.should_receive(:enqueue) do |job_class, job_status_id, feed_id, user_id|
      job_class.should eq RefreshFeedJob
      job_status = RefreshFeedJobStatus.find job_status_id
      job_status.user_id.should eq @user.id
      job_status.feed_id.should eq @feed.id
      job_status.status.should eq RefreshFeedJobStatus::RUNNING
      feed_id.should eq @feed.id
      user_id.should eq @user.id
    end

    @user.refresh_feed @feed
  end

  it 'creates a refresh_feed_job_status with state RUNNING' do
    FeedClient.stub :fetch
    RefreshFeedJobStatus.count.should eq 0

    @user.refresh_feed @feed

    RefreshFeedJobStatus.count.should eq 1
    job_status = RefreshFeedJobStatus.first
    job_status.user_id.should eq @user.id
    job_status.feed_id.should eq @feed.id
    job_status.status.should eq RefreshFeedJobStatus::RUNNING
  end

end
