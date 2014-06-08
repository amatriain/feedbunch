require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'enqueue a job to unsubscribe from a feed' do

    it 'enqueues a job to unsubscribe from a feed' do
      expect(Resque).to receive(:enqueue) do |job_class, user_id, feed_id|
        expect(job_class).to eq UnsubscribeUserJob
        expect(user_id).to eq @user.id
        expect(feed_id).to eq @feed.id
      end
      @user.enqueue_unsubscribe_job @feed
    end

    it 'does not enqueue job if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      expect(Resque).not_to receive :enqueue
      expect {@user.enqueue_unsubscribe_job feed}.to raise_error NotSubscribedError
    end
  end

  context 'unsubscribe from feed immediately' do
    it 'unsubscribes a user from a feed' do
      expect(@user.feeds.exists?(@feed.id)).to be true
      @user.unsubscribe @feed
      expect(@user.feeds.exists?(@feed.id)).to be false
    end

    it 'raises error if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.unsubscribe feed2}.to raise_error
    end

    it 'raises an error if there is a problem unsubscribing' do
      allow(SubscriptionsManager).to receive(:remove_subscription).and_raise StandardError.new
      expect {@user.unsubscribe @feed}.to raise_error
    end

    it 'does not change subscriptions to the feed by other users' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      expect(@user.feeds.exists?(@feed.id)).to be true
      expect(user2.feeds.exists?(@feed.id)).to be true

      @user.unsubscribe @feed
      expect(Feed.exists?(@feed.id)).to be true
      expect(@user.feeds.exists?(@feed.id)).to be false
      expect(user2.feeds.exists?(@feed.id)).to be true
    end

    it 'completely deletes feed if there are no more users subscribed' do
      expect(Feed.exists?(@feed.id)).to be true

      @user.unsubscribe @feed

      expect(Feed.exists?(@feed.id)).to be false
    end

    it 'does not delete feed if there are more users subscribed' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.unsubscribe @feed
      expect(Feed.exists?(@feed)).to be true
    end
  end

end
