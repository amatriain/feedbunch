require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do
    it 'does not allow empty emails' do
      user = FactoryGirl.build :user, email: nil
      expect(user).not_to be_valid
    end

    it 'does not allow duplicate emails' do
      user_dupe = FactoryGirl.build :user, email: @user.email
      expect(user_dupe.valid?).to be false
    end

    it 'does not allow duplicate names' do
      user_dupe = FactoryGirl.build :user, name: @user.name
      expect(user_dupe.valid?).to be false
    end

    it 'uses the email if no name is provided' do
      user = FactoryGirl.build :user, name: nil
      user.save!
      expect(user.name).to be_present
      expect(user.name).to eq user.email
    end
  end

  context 'relationship with folders' do
    before :each do
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
    end

    it 'deletes folders when deleting a user' do
      expect(Folder.count).to eq 1
      @user.destroy
      expect(Folder.count).to eq 0
    end

    it 'does not allow associating to the same folder more than once' do
      expect(@user.folders.count).to eq 1
      expect(@user.folders).to include @folder

      @user.folders << @folder

      expect(@user.folders.count).to eq 1
      expect(@user.folders.first).to eq @folder
    end

  end

  context 'relationship with entry states' do
    it 'retrieves entry states for subscribed feeds' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 2
      expect(@user.entry_states.where(entry_id: entry1.id).count).to eq 1
      expect(@user.entry_states.where(entry_id: entry2.id).count).to eq 1
    end

    it 'deletes entry states when deleting a user' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      expect(EntryState.count).to eq 1
      @user.destroy
      expect(EntryState.count).to eq 0
    end

    it 'does not allow duplicate entry states' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 1

      entry_state = FactoryGirl.build :entry_state, user_id: @user.id, entry_id: entry.id
      @user.entry_states << entry_state

      expect(@user.entry_states.count).to eq 1
    end

    it 'saves unread entry states for all feed entries when subscribing to a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2

      @user.subscribe feed.fetch_url
      expect(@user.entry_states.count).to eq 2
      expect(@user.entry_states.where(entry_id: entry1.id, read: false)).to be_present
      expect(@user.entry_states.where(entry_id: entry2.id, read: false)).to be_present
    end

    it 'removes entry states for all feed entries when unsubscribing from a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 2
      @user.unsubscribe feed
      expect(@user.entry_states.count).to eq 0
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

      expect(@user.entry_states.count).to eq 2
      @user.unsubscribe feed1
      expect(@user.entry_states.count).to eq 1
      expect(@user.entry_states.where(user_id: @user.id, entry_id: entry2.id)).to be_present
    end

  end

  context 'relationship with opml_import_job_states' do

    before :each do
      @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = @opml_import_job_state
    end

    it 'deletes opml_import_job_states when deleting a user' do
      expect(OpmlImportJobState.count).to eq 1
      @user.destroy
      expect(OpmlImportJobState.count).to eq 0
    end

    it 'deletes the old opml_import_job_state when adding a new one for a user' do
      expect(OpmlImportJobState.exists?(@opml_import_job_state)).to be true
      opml_import_job_state2 = FactoryGirl.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = opml_import_job_state2

      expect(OpmlImportJobState.exists?(@opml_import_job_state)).to be false
    end
  end

  context 'relationship with opml_export_job_states' do

    before :each do
      @opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = @opml_export_job_state
    end

    it 'deletes opml_export_job_states when deleting a user' do
      expect(OpmlExportJobState.count).to eq 1
      @user.destroy
      expect(OpmlExportJobState.count).to eq 0
    end

    it 'deletes the old opml_export_job_state when adding a new one for a user' do
      expect(OpmlExportJobState.exists?(@opml_export_job_state)).to be true
      opml_export_job_state2 = FactoryGirl.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = opml_export_job_state2

      expect(OpmlExportJobState.exists?(@opml_export_job_state)).to be false
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
      expect(RefreshFeedJobState.count).to eq 1
      @user.destroy
      expect(RefreshFeedJobState.count).to eq 0
    end

    it 'deletes refresh_feed_job_states when unsubscribing from a feed' do
      # a second user is subscribed to the same feed, so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      expect(RefreshFeedJobState.count).to eq 1
      @user.unsubscribe @feed
      expect(RefreshFeedJobState.count).to eq 0
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
      expect(SubscribeJobState.count).to eq 1
      @user.destroy
      expect(SubscribeJobState.count).to eq 0
    end

    it 'deletes subscribe_job_states when unsubscribing from a feed' do
      # a second user is subscribed to the same feed, so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      expect(SubscribeJobState.count).to eq 1
      @user.unsubscribe @feed
      expect(SubscribeJobState.count).to eq 0
    end
  end

  context 'locale' do

    it 'gives a default english locale' do
      user = FactoryGirl.build :user, locale: nil
      user.save!
      expect(user.locale).to eq 'en'
    end

    it 'defaults to english if the passed locale is not supported' do
      user = FactoryGirl.build :user, locale: 'not-supported-locale'
      user.save!
      expect(user.locale).to eq 'en'
    end

  end

  context 'timezone' do

    it 'gives a default UTC timezone' do
      user = FactoryGirl.build :user, timezone: nil
      user.save!
      expect(user.timezone).to eq 'UTC'
    end

    it 'defaults to UTC if the passed timezone is not supported' do
      user = FactoryGirl.build :user, timezone: 'Amber/Castle Amber'
      user.save!
      expect(user.timezone).to eq 'UTC'
    end

  end

  context 'quick reading' do

    it 'gives a default value of false' do
      user = FactoryGirl.build :user, quick_reading: nil
      user.save!
      expect(user.quick_reading).not_to be_nil
      expect(user.quick_reading).to be false
    end

    it 'defaults to false if the passed value is not supported' do
      user = FactoryGirl.build :user, quick_reading: 'not-valid-boolean'
      user.save!
      expect(user.quick_reading).to be false
    end
  end

  context 'open all entries by default' do

    it 'gives a default value of false' do
      user = FactoryGirl.build :user, open_all_entries: nil
      user.save!
      expect(user.open_all_entries).not_to be_nil
      expect(user.open_all_entries).to be false
    end

    it 'defaults to false if the passed value is not supported' do
      user = FactoryGirl.build :user, open_all_entries: 'not-valid-boolean'
      user.save!
      expect(user.open_all_entries).to be false
    end
  end

  context 'show main app tour by default' do

    it 'gives a default value of true' do
      user = FactoryGirl.build :user, show_main_tour: nil
      user.save!
      expect(user.show_main_tour).not_to be_nil
      expect(user.show_main_tour).to be true
    end
  end

  context 'show mobile app tour by default' do

    it 'gives a default value of true' do
      user = FactoryGirl.build :user, show_mobile_tour: nil
      user.save!
      expect(user.show_mobile_tour).not_to be_nil
      expect(user.show_mobile_tour).to be true
    end
  end

  context 'show feed app tour by default' do

    it 'gives a default value of true' do
      user = FactoryGirl.build :user, show_feed_tour: nil
      user.save!
      expect(user.show_feed_tour).not_to be_nil
      expect(user.show_feed_tour).to be true
    end
  end

  context 'show entry app tour by default' do

    it 'gives a default value of true' do
      user = FactoryGirl.build :user, show_entry_tour: nil
      user.save!
      expect(user.show_entry_tour).not_to be_nil
      expect(user.show_entry_tour).to be true
    end
  end

  context 'subscriptions_updated_at defaults' do

    it 'defaults to current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryGirl.build :user, subscriptions_updated_at: nil
      user.save!
      expect(user.subscriptions_updated_at).not_to be_nil
      expect(user.subscriptions_updated_at).to eq date
    end
  end

end