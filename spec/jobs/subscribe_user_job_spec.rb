require 'spec_helper'

describe SubscribeUserJob do

  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @feed = FactoryGirl.create :feed
    @url = 'http://www.galactanet.com/feed.xml'

    # Stub FeedClient.stub so that it does not actually fetch feeds, but returns them untouched
    FeedClient.stub :fetch do |feed, perform_autodiscovery|
      feed
    end
  end

  it 'does nothing if the user does not exist' do
    @user.should_not_receive :subscribe
    SubscribeUserJob.perform 1234567890, @feed.fetch_url, @folder.id, false
  end

  it 'does nothing if the folder does not exist' do
    @user.should_not_receive :subscribe
    SubscribeUserJob.perform @user.id, @feed.fetch_url, 1234567890, false
  end

  it 'does nothing if the folder is not owned by the user' do
    folder = FactoryGirl.create :folder
    @user.should_not_receive :subscribe
    SubscribeUserJob.perform @user.id, @feed.fetch_url, folder.id, false
  end

  it 'subscribes user to already existing feeds' do
    @user.feeds.should_not include @feed
    SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false
    @user.reload
    @user.feeds.should include @feed
  end

  it 'creates new feeds and subscribes user to them' do
    Feed.exists?(fetch_url: @url).should be_false
    SubscribeUserJob.perform @user.id, @url, @folder.id, false
    @user.reload
    @user.feeds.where(fetch_url: @url).should be_present
  end

  it 'fetches new feeds' do
    FeedClient.should_receive(:fetch) do |feed, autodiscovery|
      feed.fetch_url.should eq @url
      autodiscovery.should be_true
      feed
    end
    SubscribeUserJob.perform @user.id, @url, @folder.id, false
  end

  context 'running an OPML import' do

    before :each do
      @data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::RUNNING,
                                       total_feeds: 10, processed_feeds: 5
      @user.data_import = @data_import
    end

    it 'does nothing if the user does not have a running data import' do
      @user.data_import.update status: DataImport::ERROR
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true

      @user.data_import.update status: DataImport::SUCCESS
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true

      @user.data_import.destroy
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
    end

    it 'updates number of processed feeds in the running import when subscribing user to existing feeds' do
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
    end

    it 'updates number of processed feeds in the running import if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url
      # running the job will raise an AlreadySubscribedError
      expect {SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true}.to raise_error
      @user.reload
      @user.data_import.processed_feeds.should eq 6
    end

    it 'sets data import status to SUCCESS if all feeds have been processed' do
      @user.data_import.update processed_feeds: 9
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 10
      @user.data_import.status.should eq DataImport::SUCCESS
    end

    it 'sends an email if all feeds have been processed' do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear
      @user.data_import.update processed_feeds: 9
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      mail_should_be_sent to: @user.email, text: 'Your feed subscriptions have been imported into Feedbunch'
    end
  end
end