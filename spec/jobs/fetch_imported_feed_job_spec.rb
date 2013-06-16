require 'spec_helper'

describe FetchImportedFeedJob do

  before :each do
    # Ensure no actual calls to FeedClient are performed.
    FeedClient.stub :fetch

    @user = FactoryGirl.create :user
    @data_import = FactoryGirl.build :data_import, user_id: @user.id,
                                     total_feeds: 4, processed_feeds: 2,
                                     status: DataImport::RUNNING
    @user.data_import = @data_import
    @feed = FactoryGirl.create :feed
    @user.feeds << @feed
  end

  it 'fetches feed' do
    FeedClient.should_receive(:fetch).with @feed.id, true
    FetchImportedFeedJob.perform @feed.id, @user.id
  end

  it 'does not fetch feed if it does not exist' do
    @feed.destroy
    FeedClient.should_not_receive :fetch
    FetchImportedFeedJob.perform @feed.id, @user.id
  end

  it 'does nothing if user does not exist' do
    FeedClient.should_not_receive :fetch
    FetchImportedFeedJob.perform @feed.id, 1234567890
  end

  it 'increments processed feeds count if feed does not exist' do
    @feed.destroy
    FetchImportedFeedJob.perform @feed.id, @user.id
    @user.reload
    @user.data_import.processed_feeds.should eq 3
  end

  it 'increments processed feeds count if feed is fetched successfully' do
    FeedClient.stub(:fetch).and_return @feed

    FetchImportedFeedJob.perform @feed.id, @user.id
    @user.reload
    @user.data_import.processed_feeds.should eq 3
  end

  it 'increments processed feeds count if there is an error while fetching' do
    FeedClient.stub(:fetch).and_raise StandardError.new
    expect {FetchImportedFeedJob.perform @feed.id, @user.id}.to raise_error StandardError
    @user.reload
    @user.data_import.processed_feeds.should eq 3
  end

  it 'sets data import status to SUCCESS if all feeds have been fetched' do
    @user.data_import.processed_feeds = @user.data_import.total_feeds - 1
    @user.data_import.save
    FetchImportedFeedJob.perform @feed.id, @user.id
    @user.reload
    @user.data_import.status.should eq DataImport::SUCCESS
  end

  it 'does not change data import status if not all feeds have been fetched' do
    FetchImportedFeedJob.perform @feed.id, @user.id
    @user.reload
    @user.data_import.status.should eq DataImport::RUNNING
  end
end