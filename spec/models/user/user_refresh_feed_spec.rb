require 'spec_helper'

describe User do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'enqueues a job to update the feed' do
    Resque.should_receive(:enqueue) do |job_class, job_state_id, feed_id, user_id|
      job_class.should eq RefreshFeedJob
      job_state = RefreshFeedJobState.find job_state_id
      job_state.user_id.should eq @user.id
      job_state.feed_id.should eq @feed.id
      job_state.state.should eq RefreshFeedJobState::RUNNING
      feed_id.should eq @feed.id
      user_id.should eq @user.id
    end

    @user.refresh_feed @feed
  end

  it 'creates a refresh_feed_job_state with state RUNNING' do
    FeedClient.stub :fetch
    RefreshFeedJobState.count.should eq 0

    @user.refresh_feed @feed

    RefreshFeedJobState.count.should eq 1
    job_state = RefreshFeedJobState.first
    job_state.user_id.should eq @user.id
    job_state.feed_id.should eq @feed.id
    job_state.state.should eq RefreshFeedJobState::RUNNING
  end

  it 'does not enqueue job if less time than the minimum update interval has passed since the last feed update' do
    date_last_update = Time.zone.parse '2000-01-01 00:00:00'
    min_interval = Feedbunch::Application.config.min_update_interval
    date_refresh = date_last_update + min_interval - 5.minutes
    @feed.update last_fetched: date_last_update
    ActiveSupport::TimeZone.any_instance.stub(:now).and_return date_refresh

    RefreshFeedJobState.count.should eq 0
    Resque.should_not_receive :enqueue

    @user.refresh_feed @feed

    RefreshFeedJobState.count.should eq 1
    job_state = RefreshFeedJobState.first
    job_state.user_id.should eq @user.id
    job_state.feed_id.should eq @feed.id
    job_state.state.should eq RefreshFeedJobState::SUCCESS
  end

end
