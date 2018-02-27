require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'enqueues a job to update the feed' do
    expect(RefreshFeedWorker.jobs.size).to eq 0

    @user.refresh_feed @feed

    expect(RefreshFeedWorker.jobs.size).to eq 1
    job = RefreshFeedWorker.jobs.first
    expect(job['class']).to eq 'RefreshFeedWorker'

    args = job['args']

    # Check that the job state instance passed to the job is correct
    job_state_id = args[0]
    job_state = RefreshFeedJobState.find job_state_id
    expect(job_state.user_id).to eq @user.id
    expect(job_state.feed_id).to eq @feed.id
    expect(job_state.state).to eq RefreshFeedJobState::RUNNING

    # Check the rest of the arguments passed to the job
    feed_id = args[1]
    expect(feed_id).to eq @feed.id
    user_id = args[2]
    expect(user_id).to eq @user.id
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
    expect(RefreshFeedWorker.jobs.size).to eq 0

    @user.refresh_feed @feed

    expect(RefreshFeedWorker.jobs.size).to eq 0
    expect(RefreshFeedJobState.count).to eq 1
    job_state = RefreshFeedJobState.first
    expect(job_state.user_id).to eq @user.id
    expect(job_state.feed_id).to eq @feed.id
    expect(job_state.state).to eq RefreshFeedJobState::SUCCESS
  end

end
