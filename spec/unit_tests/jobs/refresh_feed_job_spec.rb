require 'rails_helper'

describe RefreshFeedJob do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @refresh_feed_job_state = FactoryGirl.create :refresh_feed_job_state, user_id: @user.id, feed_id: @feed.id
    allow(FeedClient).to receive :fetch
  end

  it 'updates feed when the job runs' do
    expect(FeedClient).to receive(:fetch).with @feed

    RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
  end

  it 'recalculates unread entries count in feed' do
    # user is subscribed to @feed with 1 entry
    user = FactoryGirl.create :user

    entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << entry

    user.subscribe @feed.fetch_url

    # @feed has an incorrect unread entry count of 10 for user
    feed_subscription = FeedSubscription.where(user_id: user.id, feed_id: @feed.id).first
    feed_subscription.update unread_entries: 10

    RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id

    # Unread count should be corrected
    expect(user.feed_unread_count(@feed)).to eq 1
  end

  context 'validations' do

    it 'updates feed even if the refresh_feed_job_state does not exist' do
      @refresh_feed_job_state.destroy
      expect(FeedClient).to receive(:fetch).with @feed

      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
    end

    it 'does not update feed if the user does not exist' do
      # subscribe a second user to the feed so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url
      @user.destroy
      expect(FeedClient).not_to receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
    end

    it 'destroys refresh_feed_job_state if the user does not exist' do
      @user.delete
      expect(FeedClient).not_to receive :fetch

      expect(RefreshFeedJobState.count).to eq 1
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(RefreshFeedJobState.count).to eq 0
    end

    it 'does not update feed if it does not exist' do
      expect(FeedClient).not_to receive :fetch
      @feed.destroy

      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
    end

    it 'destroys refresh_feed_job_state if the feed does not exist' do
      @feed.delete
      expect(FeedClient).not_to receive :fetch

      expect(RefreshFeedJobState.count).to eq 1
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(RefreshFeedJobState.count).to eq 0
    end


    it 'does not update feed if the user is not subscribed' do
      FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first.delete
      expect(FeedClient).not_to receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
    end

    it 'destroys refresh_feed_job_state if the user is not subscribed' do
      FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first.delete
      expect(FeedClient).not_to receive :fetch

      expect(RefreshFeedJobState.count).to eq 1
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(RefreshFeedJobState.count).to eq 0
    end
  end

  context 'update refresh_feed_job_state' do

    it 'does not update feed if refresh_feed_job_state is not RUNNING' do
      @refresh_feed_job_state.update state: RefreshFeedJobState::SUCCESS
      expect(FeedClient).not_to receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
    end

    it 'updates refresh_feed_job_state to SUCCESS if successful' do
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@refresh_feed_job_state.reload.state).to eq RefreshFeedJobState::SUCCESS
    end

    it 'updates refresh_feed_job_state to ERROR if an error is raised when fetching feed' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new

      expect(@refresh_feed_job_state.reload.state).to eq RefreshFeedJobState::RUNNING
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@refresh_feed_job_state.reload.state).to eq RefreshFeedJobState::ERROR
    end
  end

  context 'failing feed' do

    it 'sets failing_since to nil when an update runs successfully' do
      allow(FeedClient).to receive(:fetch)
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      expect(@feed.failing_since).to eq date
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@feed.reload.failing_since).to be_nil
    end

    it 'sets available to true when an update runs successfully' do
      @feed.update available: false

      expect(@feed.reload.available).to be false
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@feed.reload.available).to be true
    end

    it 'does not change failing_since if the feed update fails' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      expect(@feed.failing_since).to eq date2
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@feed.reload.failing_since).to eq date2
    end

    it 'does not mark feed as available when the feed update fails' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      @feed.update available:false

      expect(@feed.available).to be false
      RefreshFeedJob.perform @refresh_feed_job_state.id, @feed.id, @user.id
      expect(@feed.reload.available).to be false
    end
  end

end