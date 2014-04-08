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

  context 'validations' do

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

  end

  context 'running an OPML import' do

    before :each do
      @data_import = FactoryGirl.build :data_import, user_id: @user.id, state: DataImport::RUNNING,
                                       total_feeds: 10, processed_feeds: 5
      @user.data_import = @data_import

      # Resque informs there is one more instance of SubscribeUserJob enqueued.
      enqueued_job = {'class' => 'SubscribeUserJob', 'args' => [@user.id, 'http://some.url.com', nil, true]}
      Resque.stub(:peek) do |queue, start|
        if start == 0
          enqueued_job
        else
          nil
        end
      end

      # Resque always informs there is only one running SubscribeUserJob running.
      this_job = {'payload' => {'class' => 'SubscribeUserJob', 'args' => [@user.id, @feed.fetch_url, @folder.id, true]}}
      @this_working_mock = double 'Working', job: this_job
      Resque.stub(:working).and_return [@this_working_mock]
    end

    it 'does nothing if the user does not have a running data import' do
      @user.data_import.update state: DataImport::ERROR
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true

      @user.data_import.update state: DataImport::SUCCESS
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
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
    end

    it 'sets data import state to SUCCESS if all feeds have been processed' do
      @user.data_import.update processed_feeds: 9
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 10
      @user.data_import.state.should eq DataImport::SUCCESS
    end

    it 'leaves data import as RUNNING if more SubscribeUserJob instances are running' do
      another_job = {'payload' => {'class' => 'SubscribeUserJob', 'args' => [@user.id, 'http://another.url', @folder.id, true]}}
      another_working_mock = double 'Working', job: another_job
      Resque.stub(:working).and_return [@this_working_mock, another_working_mock]
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
      @user.data_import.state.should eq DataImport::RUNNING
    end

    it 'sets data import state to SUCCESS if this is the only SubscribeUserJob running and no other is enqueued' do
      Resque.stub(:peek).and_return nil
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
      @user.data_import.state.should eq DataImport::SUCCESS
    end

    it 'leaves data import as RUNNING if more SubscribeUserJob instances are enqueued' do
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
      @user.data_import.state.should eq DataImport::RUNNING
    end

    it 'sets data import state to SUCCESS if no import-related jobs are running or enqueued' do
      Resque.stub(:peek).and_return nil
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true
      @user.reload
      @user.data_import.processed_feeds.should eq 6
      @user.data_import.state.should eq DataImport::SUCCESS
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