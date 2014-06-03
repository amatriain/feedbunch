require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'enqueue a job to unsubscribe from a feed' do

    it 'enqueues a job to unsubscribe from a feed' do
      Resque.should_receive(:enqueue) do |job_class, user_id, feed_id|
        job_class.should eq UnsubscribeUserJob
        user_id.should eq @user.id
        feed_id.should eq @feed.id
      end
      @user.enqueue_unsubscribe_job @feed
    end

    it 'does not enqueue job if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      Resque.should_not_receive :enqueue
      expect {@user.enqueue_unsubscribe_job feed}.to raise_error NotSubscribedError
    end
  end

  context 'unsubscribe from feed immediately' do
    it 'unsubscribes a user from a feed' do
      @user.feeds.exists?(@feed.id).should be_true
      @user.unsubscribe @feed
      @user.feeds.exists?(@feed.id).should be_false
    end

    it 'raises error if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.unsubscribe feed2}.to raise_error
    end

    it 'raises an error if there is a problem unsubscribing' do
      SubscriptionsManager.stub(:remove_subscription).and_raise StandardError.new
      expect {@user.unsubscribe @feed}.to raise_error
    end

    it 'does not change subscriptions to the feed by other users' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.feeds.exists?(@feed.id).should be_true
      user2.feeds.exists?(@feed.id).should be_true

      @user.unsubscribe @feed
      Feed.exists?(@feed.id).should be_true
      @user.feeds.exists?(@feed.id).should be_false
      user2.feeds.exists?(@feed.id).should be_true
    end

    it 'completely deletes feed if there are no more users subscribed' do
      Feed.exists?(@feed.id).should be_true

      @user.unsubscribe @feed

      Feed.exists?(@feed.id).should be_false
    end

    it 'does not delete feed if there are more users subscribed' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.unsubscribe @feed
      Feed.exists?(@feed).should be_true
    end
  end

end
