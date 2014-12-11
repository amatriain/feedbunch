require 'rails_helper'

describe SubscribeUserWorker do

  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @feed = FactoryGirl.create :feed
    @url = 'http://www.galactanet.com/feed.xml'
    @job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url
    @user.subscribe_job_states << @job_state

    # Stub FeedClient.stub so that it does not actually fetch feeds, but returns them untouched
    allow(FeedClient).to receive :fetch do |feed, perform_autodiscovery|
      feed
    end
  end

  it 'subscribes user to already existing feeds' do
    expect(@user.feeds).not_to include @feed
    SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @job_state.id
    @user.reload
    expect(@user.feeds).to include @feed
  end

  it 'creates new feeds and subscribes user to them' do
    expect(Feed.exists?(fetch_url: @url)).to be false
    SubscribeUserWorker.new.perform @user.id, @url, @job_state.id
    @user.reload
    expect(@user.feeds.where(fetch_url: @url)).to be_present
  end

  it 'fetches new feeds' do
    expect(FeedClient).to receive(:fetch) do |feed, autodiscovery|
      expect(feed.fetch_url).to eq @url
      expect(autodiscovery).to be true
      feed
    end
    SubscribeUserWorker.new.perform @user.id, @url, @job_state.id
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      expect_any_instance_of(User).not_to receive :subscribe
      SubscribeUserWorker.new.perform 1234567890, @feed.fetch_url, @job_state.id
    end

    it 'destroys subscribe_job_state if the user does not exist' do
      subscribe_job_state = FactoryGirl.create :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url
      @user.delete

      expect(SubscribeJobState.count).to eq 2
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, subscribe_job_state.id
      expect(SubscribeJobState.count).to eq 1
    end

    it 'does nothing if job_state does not exist' do
      expect_any_instance_of(User).not_to receive :subscribe
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, 'not_a_valid_id'
    end

    it 'does nothing if the job_state is not in state RUNNING' do
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url,
                                    state: SubscribeJobState::ERROR
      @user.subscribe_job_states << job_state
      expect(@user).not_to receive :subscribe
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, job_state.id
    end

  end

  context 'running an OPML import' do

    before :each do
      @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                       total_feeds: 10, processed_feeds: 5
      @user.opml_import_job_state = @opml_import_job_state
    end

    it 'updates number of processed feeds in the running import when subscribing user to existing feeds' do
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      expect(@user.opml_import_job_state.processed_feeds).to eq 6
    end

    it 'updates number of processed feeds in the running import if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      @user.reload
      expect(@user.opml_import_job_state.processed_feeds).to eq 6
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::RUNNING
    end

    it 'updates number of processed feeds in the running import if an error is raised' do
      allow_any_instance_of(User).to receive(:subscribe).and_raise StandardError.new

      expect{SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @folder.id, true, nil}.to raise_error(StandardError)

      @user.reload
      expect(@user.opml_import_job_state.processed_feeds).to eq 6
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::RUNNING
    end



    it 'sends an email if all feeds have been processed' do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear
      @user.opml_import_job_state.update processed_feeds: 9
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @folder.id, true, nil
      mail_should_be_sent to: @user.email, text: 'Your feed subscriptions have been imported into Feedbunch'
    end
  end

  context 'updates job state' do

    it 'sets state to SUCCESS if job finishes successfully' do
      expect(@job_state.state).to eq SubscribeJobState::RUNNING
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @job_state.id
      expect(@job_state.reload.state).to eq SubscribeJobState::SUCCESS
    end

    it 'saves feed id if job finishes successfully' do
      expect(@job_state.feed).to be_blank
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @job_state.id
      expect(@job_state.reload.feed).to eq @feed
    end

    it 'sets state to ERROR if job finishes with an error' do
      allow_any_instance_of(User).to receive(:subscribe).and_raise SocketError.new
      expect(@job_state.state).to eq SubscribeJobState::RUNNING
      SubscribeUserWorker.new.perform @user.id, @feed.fetch_url, @job_state.id
      expect(@job_state.reload.state).to eq SubscribeJobState::ERROR
    end

  end
end