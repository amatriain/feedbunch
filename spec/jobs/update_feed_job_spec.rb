require 'spec_helper'

describe UpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
    FeedClient.stub :fetch
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed, anything

    UpdateFeedJob.perform @feed.id
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

    UpdateFeedJob.perform @feed.id

    # Unread count should be corrected
    user.feed_unread_count(@feed).should eq 1
  end

  it 'unschedules updates if the feed has been deleted when the job runs' do
    @feed.destroy
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"
    FeedClient.should_not_receive :fetch

    UpdateFeedJob.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    FeedClient.should_not_receive :fetch
    @feed.destroy

    UpdateFeedJob.perform @feed.id
  end

end