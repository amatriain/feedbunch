require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do
    it 'does now allow empty emails' do
      user = FactoryGirl.build :user, email: nil
      user.should_not be_valid
    end

    it 'does not allow duplicate emails' do
      user_dupe = FactoryGirl.build :user, email: @user.email
      user_dupe.valid?.should be_false
    end

    it 'does not allow duplicate names' do
      user_dupe = FactoryGirl.build :user, name: @user.name
      user_dupe.valid?.should be_false
    end

    it 'uses the email if no name is provided' do
      user = FactoryGirl.build :user, name: nil
      user.save!
      user.name.should be_present
      user.name.should eq user.email
    end
  end

  context 'relationship with folders' do
    before :each do
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
    end

    it 'deletes folders when deleting a user' do
      Folder.count.should eq 1
      @user.destroy
      Folder.count.should eq 0
    end

    it 'does not allow associating to the same folder more than once' do
      @user.folders.count.should eq 1
      @user.folders.should include @folder

      @user.folders << @folder

      @user.folders.count.should eq 1
      @user.folders.first.should eq @folder
    end

  end

  context 'relationship with entry states' do
    it 'retrieves entry states for subscribed feeds' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      @user.entry_states.count.should eq 2
      @user.entry_states.where(entry_id: entry1.id).count.should eq 1
      @user.entry_states.where(entry_id: entry2.id).count.should eq 1
    end

    it 'deletes entry states when deleting a user' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      EntryState.count.should eq 1
      @user.destroy
      EntryState.count.should eq 0
    end

    it 'does not allow duplicate entry states' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      @user.entry_states.count.should eq 1

      entry_state = FactoryGirl.build :entry_state, user_id: @user.id, entry_id: entry.id
      @user.entry_states << entry_state

      @user.entry_states.count.should eq 1
    end

    it 'saves unread entry states for all feed entries when subscribing to a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2

      @user.subscribe feed.fetch_url
      @user.entry_states.count.should eq 2
      @user.entry_states.where(entry_id: entry1.id, read: false).should be_present
      @user.entry_states.where(entry_id: entry2.id, read: false).should be_present
    end

    it 'removes entry states for all feed entries when unsubscribing from a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      @user.entry_states.count.should eq 2
      @user.unsubscribe feed
      @user.entry_states.count.should eq 0
    end

    it 'does not affect entry states for other feeds when unsubscribing from a feed' do
      feed1 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1
      feed2 = FactoryGirl.create :feed
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry2
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url

      @user.entry_states.count.should eq 2
      @user.unsubscribe feed1
      @user.entry_states.count.should eq 1
      @user.entry_states.where(user_id: @user.id, entry_id: entry2.id).should be_present
    end

  end

  context 'relationship with opml_import_job_states' do

    before :each do
      @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = @opml_import_job_state
    end

    it 'deletes opml_import_job_states when deleting a user' do
      OpmlImportJobState.count.should eq 1
      @user.destroy
      OpmlImportJobState.count.should eq 0
    end

    it 'deletes the old opml_import_job_state when adding a new one for a user' do
      OpmlImportJobState.exists?(@opml_import_job_state).should be_true
      opml_import_job_state2 = FactoryGirl.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = opml_import_job_state2

      OpmlImportJobState.exists?(@opml_import_job_state).should be_false
    end
  end

  context 'relationship with opml_export_job_states' do

    before :each do
      @opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = @opml_export_job_state
    end

    it 'deletes opml_export_job_states when deleting a user' do
      OpmlExportJobState.count.should eq 1
      @user.destroy
      OpmlExportJobState.count.should eq 0
    end

    it 'deletes the old opml_export_job_state when adding a new one for a user' do
      OpmlExportJobState.exists?(@opml_export_job_state).should be_true
      opml_export_job_state2 = FactoryGirl.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = opml_export_job_state2

      OpmlExportJobState.exists?(@opml_export_job_state).should be_false
    end
  end

  context 'relationship with refresh_feed_job_states' do

    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
      @refresh_feed_job_state = FactoryGirl.build :refresh_feed_job_state, feed_id: @feed.id, user_id: @user.id
      @feed.refresh_feed_job_states << @refresh_feed_job_state
      @user.refresh_feed_job_states << @refresh_feed_job_state
    end

    it 'deletes refresh_feed_job_states when deleting a user' do
      RefreshFeedJobState.count.should eq 1
      @user.destroy
      RefreshFeedJobState.count.should eq 0
    end

    it 'deletes refresh_feed_job_states when unsubscribing from a feed' do
      # a second user is subscribed to the same feed, so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      RefreshFeedJobState.count.should eq 1
      @user.unsubscribe @feed
      RefreshFeedJobState.count.should eq 0
    end
  end

  context 'relationship with subscribe_job_states' do

    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
      @subscribe_job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url, feed_id: @feed.id,
                                               state: SubscribeJobState::SUCCESS
      @user.subscribe_job_states << @subscribe_job_state
      @feed.subscribe_job_states << @subscribe_job_state
    end

    it 'deletes subscribe_job_states when deleting a user' do
      SubscribeJobState.count.should eq 1
      @user.destroy
      SubscribeJobState.count.should eq 0
    end

    it 'deletes subscribe_job_states when unsubscribing from a feed' do
      # a second user is subscribed to the same feed, so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      SubscribeJobState.count.should eq 1
      @user.unsubscribe @feed
      SubscribeJobState.count.should eq 0
    end
  end

  context 'locale' do

    it 'gives a default english locale' do
      user = FactoryGirl.build :user, locale: nil
      user.save!
      user.locale.should eq 'en'
    end

    it 'defaults to english if the passed locale is not supported' do
      user = FactoryGirl.build :user, locale: 'not-supported-locale'
      user.save!
      user.locale.should eq 'en'
    end

  end

  context 'timezone' do

    it 'gives a default UTC timezone' do
      user = FactoryGirl.build :user, timezone: nil
      user.save!
      user.timezone.should eq 'UTC'
    end

    it 'defaults to UTC if the passed timezone is not supported' do
      user = FactoryGirl.build :user, timezone: 'Amber/Castle Amber'
      user.save!
      user.timezone.should eq 'UTC'
    end

  end

  context 'quick reading' do

    it 'gives a default value of false' do
      user = FactoryGirl.build :user, quick_reading: nil
      user.save!
      user.quick_reading.should_not be_nil
      user.quick_reading.should be_false
    end

    it 'defaults to false if the passed value is not supported' do
      user = FactoryGirl.build :user, quick_reading: 'not-valid-boolean'
      user.save!
      user.quick_reading.should be_false
    end
  end

  context 'open all entries by default' do

    it 'gives a default value of false' do
      user = FactoryGirl.build :user, open_all_entries: nil
      user.save!
      user.open_all_entries.should_not be_nil
      user.open_all_entries.should be_false
    end

    it 'defaults to false if the passed value is not supported' do
      user = FactoryGirl.build :user, open_all_entries: 'not-valid-boolean'
      user.save!
      user.open_all_entries.should be_false
    end
  end

end