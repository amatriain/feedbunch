require 'rails_helper'

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
    SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false, nil
    @user.reload
    @user.feeds.should include @feed
  end

  it 'creates new feeds and subscribes user to them' do
    Feed.exists?(fetch_url: @url).should be false
    SubscribeUserJob.perform @user.id, @url, @folder.id, false, nil
    @user.reload
    @user.feeds.where(fetch_url: @url).should be_present
  end

  it 'fetches new feeds' do
    FeedClient.should_receive(:fetch) do |feed, autodiscovery|
      feed.fetch_url.should eq @url
      autodiscovery.should be true
      feed
    end
    SubscribeUserJob.perform @user.id, @url, @folder.id, false, nil
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      User.any_instance.should_not_receive :subscribe
      SubscribeUserJob.perform 1234567890, @feed.fetch_url, @folder.id, false, nil
    end

    it 'does nothing if the folder does not exist' do
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, 1234567890, false, nil
    end

    it 'does nothing if the folder is not owned by the user' do
      folder = FactoryGirl.create :folder
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, folder.id, false, nil
    end

    it 'does nothing if the job_status is not in state RUNNING' do
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url,
                                    state: SubscribeJobState::ERROR
      @user.subscribe_job_states << job_state
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false, job_state.id
    end

  end

  context 'running an OPML import' do

    before :each do
      @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                       total_feeds: 10, processed_feeds: 5
      @user.opml_import_job_state = @opml_import_job_state

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
      @user.opml_import_job_state.update state: OpmlImportJobState::ERROR
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil

      @user.opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil

      @user.opml_import_job_state.destroy
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
    end

    it 'updates number of processed feeds in the running import when subscribing user to existing feeds' do
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
    end

    it 'updates number of processed feeds in the running import if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
    end

    it 'sets data import state to SUCCESS if all feeds have been processed' do
      @user.opml_import_job_state.update processed_feeds: 9
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 10
      @user.opml_import_job_state.state.should eq OpmlImportJobState::SUCCESS
    end

    it 'leaves data import as RUNNING if more SubscribeUserJob instances are running' do
      another_job = {'payload' => {'class' => 'SubscribeUserJob', 'args' => [@user.id, 'http://another.url', @folder.id, true]}}
      another_working_mock = double 'Working', job: another_job
      Resque.stub(:working).and_return [@this_working_mock, another_working_mock]
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
      @user.opml_import_job_state.state.should eq OpmlImportJobState::RUNNING
    end

    it 'sets data import state to SUCCESS if this is the only SubscribeUserJob running and no other is enqueued' do
      Resque.stub(:peek).and_return nil
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
      @user.opml_import_job_state.state.should eq OpmlImportJobState::SUCCESS
    end

    it 'leaves data import as RUNNING if more SubscribeUserJob instances are enqueued' do
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
      @user.opml_import_job_state.state.should eq OpmlImportJobState::RUNNING
    end

    it 'sets data import state to SUCCESS if no import-related jobs are running or enqueued' do
      Resque.stub(:peek).and_return nil
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      @user.opml_import_job_state.processed_feeds.should eq 6
      @user.opml_import_job_state.state.should eq OpmlImportJobState::SUCCESS
    end

    it 'sends an email if all feeds have been processed' do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear
      @user.opml_import_job_state.update processed_feeds: 9
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      mail_should_be_sent to: @user.email, text: 'Your feed subscriptions have been imported into Feedbunch'
    end
  end

  context 'updates job state' do

    before :each do
      @job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url
      @user.subscribe_job_states << @job_state
    end

    it 'sets state to SUCCESS if job finishes successfully' do
      @job_state.state.should eq SubscribeJobState::RUNNING
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false, @job_state.id
      @job_state.reload.state.should eq SubscribeJobState::SUCCESS
    end

    it 'saves feed id if job finishes successfully' do
      @job_state.feed.should be_blank
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false, @job_state.id
      @job_state.reload.feed.should eq @feed
    end

    it 'sets state to ERROR if job finishes with an error' do
      User.any_instance.stub(:subscribe).and_raise SocketError.new
      @job_state.state.should eq SubscribeJobState::RUNNING
      SubscribeUserJob.perform @user.id, @feed.fetch_url, @folder.id, false, @job_state.id
      @job_state.reload.state.should eq SubscribeJobState::ERROR
    end

  end
end