require 'rails_helper'

describe ImportSubscriptionWorker do

  before :each do
    @user = FactoryGirl.create :user
    @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.opml_import_job_state = @opml_import_job_state

    @url = 'http://some.feed.com/'
    @feed = FactoryGirl.create :feed, fetch_url: @url

    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
  end

  context 'validations' do

    it 'does nothing if the job state does not exist' do
      expect(URLSubscriber).not_to receive :subscribe
      ImportSubscriptionWorker.new.perform 1234567890, @url
    end

    it 'does nothing if the opml_import_job_state has state NONE' do
      @user.opml_import_job_state.update state: OpmlImportJobState::NONE
      expect(URLSubscriber).not_to receive :subscribe
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
    end

    it 'does nothing if the opml_import_job_state has state ERROR' do
      @user.opml_import_job_state.update state: OpmlImportJobState::ERROR
      expect(URLSubscriber).not_to receive :subscribe
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
    end

    it 'does nothing if the opml_import_job_state has state SUCCESS' do
      @user.opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      expect(URLSubscriber).not_to receive :subscribe
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
    end

    it 'ignores folder if it does not exist' do
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url, 1234567890
      # @user should be subscribed to @feed
      expect(@user.reload.feeds.count).to eq 1
      feed = @user.feeds.first
      expect(feed.fetch_url).to eq @url
      # feed should not be in any folder
      expect(feed.user_folder @user).to be_nil
    end

    it 'ignores folder if it is owned by a different user' do
      user2 = FactoryGirl.create :user
      folder2 = FactoryGirl.build :folder, user_id: user2.id
      user2.folders << folder2

      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url, folder2.id
      # @user should be subscribed to @feed
      expect(@user.reload.feeds.count).to eq 1
      feed = @user.feeds.first
      expect(feed.fetch_url).to eq @url
      # feed should not be in any folder
      expect(feed.user_folder @user).to be_nil
    end

  end

  context 'total processed feeds count' do

    it 'increments count when finishes successfully' do
      expect(@opml_import_job_state.processed_feeds).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(@opml_import_job_state.reload.processed_feeds).to eq 1
    end

    it 'increments count when finishes with an error' do
      allow(URLSubscriber).to receive(:subscribe).and_raise StandardError.new
      expect(@opml_import_job_state.processed_feeds).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(@opml_import_job_state.reload.processed_feeds).to eq 1
    end

    it 'does not increment count if opml_import_job_state has state NONE' do
      @user.opml_import_job_state.update state: OpmlImportJobState::NONE
      expect(@opml_import_job_state.processed_feeds).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(@opml_import_job_state.reload.processed_feeds).to eq 0
    end

    it 'does not increment count if opml_import_job_state has state ERROR' do
      @user.opml_import_job_state.update state: OpmlImportJobState::ERROR
      expect(@opml_import_job_state.processed_feeds).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(@opml_import_job_state.reload.processed_feeds).to eq 0
    end

    it 'does not increment count if opml_import_job_state has state SUCCESS' do
      @user.opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      expect(@opml_import_job_state.processed_feeds).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(@opml_import_job_state.reload.processed_feeds).to eq 0
    end

  end

  context 'finishes successfully' do

    it 'subscribes user to feed' do
      expect(@user.feeds.count).to eq 0

      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url

      expect(@user.reload.feeds.count).to eq 1
      expect(@user.feeds.first.fetch_url).to eq @url
    end

    it 'puts subscribed feed in passed folder' do
      expect(@folder.feeds.count).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url, @folder.id
      expect(@folder.reload.feeds.count).to eq 1
      expect(@folder.feeds.first.id).to eq @feed.id
    end
  end

  context 'failed URLs during import' do

    it 'creates OpmlImportFailure instance if an error is raised' do
      allow(URLSubscriber).to receive(:subscribe).and_raise StandardError.new
      expect(OpmlImportFailure.all.count).to eq 0
      ImportSubscriptionWorker.new.perform @opml_import_job_state.id, @url
      expect(OpmlImportFailure.all.count).to eq 1
      expect(OpmlImportFailure.first.url).to eq @url
    end
  end

end