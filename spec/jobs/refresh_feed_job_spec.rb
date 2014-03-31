require 'spec_helper'

describe RefreshFeedJob do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @refresh_feed_job_status = FactoryGirl.create :refresh_feed_job_status, user_id: @user.id, feed_id: @feed.id
    FeedClient.stub :fetch
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed

    RefreshFeedJob.perform @refresh_feed_job_status.id
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

    RefreshFeedJob.perform @refresh_feed_job_status.id

    # Unread count should be corrected
    user.feed_unread_count(@feed).should eq 1
  end

  context 'validations' do

    it 'does not update feed if the refresh_feed_job_status does not exist' do
      @refresh_feed_job_status.destroy
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_status.id
    end

    it 'does not update feed if the user does not exist' do
      # subscribe a second user to the feed so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url
      @user.destroy
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_status.id
    end

    it 'destroys refresh_feed_job_status if the user does not exist' do
      @user.delete
      FeedClient.should_not_receive :fetch

      RefreshFeedJobStatus.count.should eq 1
      RefreshFeedJob.perform @refresh_feed_job_status.id
      RefreshFeedJobStatus.count.should eq 0
    end

    it 'does not update feed if it does not exist' do
      FeedClient.should_not_receive :fetch
      @feed.destroy

      RefreshFeedJob.perform @refresh_feed_job_status.id
    end

    it 'destroys refresh_feed_job_status if the feed does not exist' do
      @feed.delete
      FeedClient.should_not_receive :fetch

      RefreshFeedJobStatus.count.should eq 1
      RefreshFeedJob.perform @refresh_feed_job_status.id
      RefreshFeedJobStatus.count.should eq 0
    end


    it 'does not update feed if the user is not subscribed' do
      FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first.delete
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_status.id
    end

    it 'destroys refresh_feed_job_status if the user is not subscribed' do
      FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first.delete
      FeedClient.should_not_receive :fetch

      RefreshFeedJobStatus.count.should eq 1
      RefreshFeedJob.perform @refresh_feed_job_status.id
      RefreshFeedJobStatus.count.should eq 0
    end
  end

  context 'update refresh_feed_job_status' do

    it 'does not update feed if refresh_feed_job_status is not RUNNING' do
      @refresh_feed_job_status.update status: RefreshFeedJobStatus::SUCCESS
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform @refresh_feed_job_status.id
    end

    it 'updates refresh_feed_job_status to SUCCESS if successful' do
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @refresh_feed_job_status.reload.status.should eq RefreshFeedJobStatus::SUCCESS
    end

    it 'updates refresh_feed_job_status to ERROR if an error is raised when fetching feed' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new

      @refresh_feed_job_status.reload.status.should eq RefreshFeedJobStatus::RUNNING
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @refresh_feed_job_status.reload.status.should eq RefreshFeedJobStatus::ERROR
    end
  end

  context 'failing feed' do

    it 'sets failing_since to nil when an update runs successfully' do
      FeedClient.stub(:fetch)
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      @feed.failing_since.should eq date
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @feed.reload.failing_since.should be_nil
    end

    it 'sets available to true when an update runs successfully' do
      @feed.update available: false

      @feed.reload.available.should be_false
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @feed.reload.available.should be_true
    end

    it 'does not change failing_since if the feed update fails' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      @feed.failing_since.should eq date2
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @feed.reload.failing_since.should eq date2
    end

    it 'does not mark feed as available when the feed update fails' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      @feed.update available:false

      @feed.available.should be_false
      RefreshFeedJob.perform @refresh_feed_job_status.id
      @feed.reload.available.should be_false
    end
  end

end