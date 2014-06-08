require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'enqueues a job to update the feed' do
    expect(Resque).to receive(:enqueue) do |job_class, job_state_id, feed_id, user_id|
      expect(job_class).to eq RefreshFeedJob
      job_state = RefreshFeedJobState.find job_state_id
      expect(job_state.user_id).to eq @user.id
      expect(job_state.feed_id).to eq @feed.id
      expect(job_state.state).to eq RefreshFeedJobState::RUNNING
      expect(feed_id).to eq @feed.id
      expect(user_id).to eq @user.id
    end

    @user.refresh_feed @feed
  end

  it 'creates a refresh_feed_job_state with state RUNNING' do
    expect(RefreshFeedJobState.count).to eq 0

    @user.refresh_feed @feed

    expect(RefreshFeedJobState.count).to eq 1
    job_state = RefreshFeedJobState.first
    expect(job_state.user_id).to eq @user.id
    expect(job_state.feed_id).to eq @feed.id
    expect(job_state.state).to eq RefreshFeedJobState::RUNNING
  end

  it 'does not enqueue job if less time than the minimum update interval has passed since the last feed update' do
    date_last_update = Time.zone.parse '2000-01-01 00:00:00'
    min_interval = Feedbunch::Application.config.min_update_interval
    date_refresh = date_last_update + min_interval - 5.minutes
    @feed.update last_fetched: date_last_update
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date_refresh

    expect(RefreshFeedJobState.count).to eq 0
    expect(Resque).not_to receive :enqueue

    @user.refresh_feed @feed

    expect(RefreshFeedJobState.count).to eq 1
    job_state = RefreshFeedJobState.first
    expect(job_state.user_id).to eq @user.id
    expect(job_state.feed_id).to eq @feed.id
    expect(job_state.state).to eq RefreshFeedJobState::SUCCESS
  end

end
