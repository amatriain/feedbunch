require 'spec_helper'

describe User do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'fetches a feed' do
    FeedClient.should_receive(:fetch).with @feed, anything
    @user.refresh_feed @feed
  end

  it 'raises an error if the user is not subscribed to the feed' do
    feed2 = FactoryGirl.create :feed
    expect {@user.refresh_feed feed2}.to raise_error NotSubscribedError
  end

end
