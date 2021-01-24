# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryBot.create :user
  end

  context 'validations' do
    it 'does not allow empty emails' do
      user = FactoryBot.build :user, email: nil
      expect(user).not_to be_valid
    end

    it 'does not allow duplicate emails' do
      user_dupe = FactoryBot.build :user, email: @user.email
      expect(user_dupe.valid?).to be false
    end

    it 'does not allow duplicate names' do
      user_dupe = FactoryBot.build :user, name: @user.name
      expect(user_dupe.valid?).to be false
    end

    it 'uses the email if no name is provided' do
      user = FactoryBot.build :user, name: nil
      user.save!
      expect(user.name).to be_present
      expect(user.name).to eq user.email
    end
  end

  context 'relationship with folders' do
    before :each do
      @folder = FactoryBot.build :folder, user_id: @user.id
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
      feed = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed.id
      entry2 = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 2
      expect(@user.entry_states.where(entry_id: entry1.id).count).to eq 1
      expect(@user.entry_states.where(entry_id: entry2.id).count).to eq 1
    end

    it 'deletes entry states when deleting a user' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      expect(EntryState.count).to eq 1
      @user.destroy
      expect(EntryState.count).to eq 0
    end

    it 'does not allow duplicate entry states' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 1

      entry_state = FactoryBot.build :entry_state, user_id: @user.id, entry_id: entry.id
      @user.entry_states << entry_state

      expect(@user.entry_states.count).to eq 1
    end

    it 'saves unread entry states for all feed entries when subscribing to a feed' do
      feed = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed.id
      entry2 = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2

      @user.subscribe feed.fetch_url
      expect(@user.entry_states.count).to eq 2
      expect(@user.entry_states.where(entry_id: entry1.id, read: false)).to be_present
      expect(@user.entry_states.where(entry_id: entry2.id, read: false)).to be_present
    end

    it 'removes entry states for all feed entries when unsubscribing from a feed' do
      feed = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed.id
      entry2 = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      expect(@user.entry_states.count).to eq 2
      @user.unsubscribe feed
      expect(@user.entry_states.count).to eq 0
    end

    it 'does not affect entry states for other feeds when unsubscribing from a feed' do
      feed1 = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed1.id
      feed1.entries << entry1
      feed2 = FactoryBot.create :feed
      entry2 = FactoryBot.build :entry, feed_id: feed2.id
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
      @opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = @opml_import_job_state
    end

    it 'deletes opml_import_job_states when deleting a user' do
      expect(OpmlImportJobState.count).to eq 1
      @user.destroy
      expect(OpmlImportJobState.count).to eq 0
    end

    it 'deletes the old opml_import_job_state when adding a new one for a user' do
      expect(OpmlImportJobState.exists? @opml_import_job_state.id).to be true
      opml_import_job_state2 = FactoryBot.build :opml_import_job_state, user_id: @user.id
      @user.opml_import_job_state = opml_import_job_state2

      expect(OpmlImportJobState.exists? @opml_import_job_state.id).to be false
    end
  end

  context 'relationship with opml_export_job_states' do

    before :each do
      @opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = @opml_export_job_state
    end

    it 'deletes opml_export_job_states when deleting a user' do
      expect(OpmlExportJobState.count).to eq 1
      @user.destroy
      expect(OpmlExportJobState.count).to eq 0
    end

    it 'deletes the old opml_export_job_state when adding a new one for a user' do
      expect(OpmlExportJobState.exists? @opml_export_job_state.id).to be true
      opml_export_job_state2 = FactoryBot.build :opml_export_job_state, user_id: @user.id
      @user.opml_export_job_state = opml_export_job_state2

      expect(OpmlExportJobState.exists? @opml_export_job_state.id).to be false
    end
  end

  context 'relationship with refresh_feed_job_states' do

    before :each do
      @feed = FactoryBot.create :feed
      @user.subscribe @feed.fetch_url
      @refresh_feed_job_state = FactoryBot.build :refresh_feed_job_state, feed_id: @feed.id, user_id: @user.id
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
      user2 = FactoryBot.create :user
      user2.subscribe @feed.fetch_url

      expect(RefreshFeedJobState.count).to eq 1
      @user.unsubscribe @feed
      expect(RefreshFeedJobState.count).to eq 0
    end
  end

  context 'relationship with subscribe_job_states' do

    before :each do
      @feed = FactoryBot.create :feed
      @user.subscribe @feed.fetch_url
      @subscribe_job_state = FactoryBot.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed.fetch_url, feed_id: @feed.id,
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
      user2 = FactoryBot.create :user
      user2.subscribe @feed.fetch_url

      expect(SubscribeJobState.count).to eq 1
      @user.unsubscribe @feed
      expect(SubscribeJobState.count).to eq 0
    end
  end

  context 'locale' do

    it 'gives a default english locale' do
      user = FactoryBot.build :user, locale: nil
      user.save!
      expect(user.reload.locale).to eq 'en'
    end

    it 'defaults to english if the passed locale is not supported' do
      user = FactoryBot.build :user, locale: 'not-supported-locale'
      user.save!
      expect(user.reload.locale).to eq 'en'
    end

  end

  context 'timezone' do

    it 'gives a default UTC timezone' do
      user = FactoryBot.build :user, timezone: nil
      user.save!
      expect(user.timezone).to eq 'UTC'
    end

    it 'defaults to UTC if the passed timezone is not supported' do
      user = FactoryBot.build :user, timezone: 'Amber/Castle Amber'
      user.save!
      expect(user.reload.timezone).to eq 'UTC'
    end

  end

  context 'admin' do

    it 'gives a default value of false' do
      user = FactoryBot.build :user, admin: nil
      user.save!
      expect(user.reload.admin).not_to be_nil
      expect(user.admin).to be false
    end
  end

  context 'quick reading' do

    it 'gives a default value of false' do
      user = FactoryBot.build :user, quick_reading: nil
      user.save!
      expect(user.reload.quick_reading).not_to be_nil
      expect(user.quick_reading).to be false
    end
  end

  context 'open all entries by default' do

    it 'gives a default value of false' do
      user = FactoryBot.build :user, open_all_entries: nil
      user.save!
      expect(user.reload.open_all_entries).not_to be_nil
      expect(user.open_all_entries).to be false
    end
  end

  context 'show main app tour by default' do

    it 'gives a default value of true' do
      user = FactoryBot.build :user, show_main_tour: nil
      user.save!
      expect(user.reload.show_main_tour).not_to be_nil
      expect(user.show_main_tour).to be true
    end
  end

  context 'show mobile app tour by default' do

    it 'gives a default value of true' do
      user = FactoryBot.build :user, show_mobile_tour: nil
      user.save!
      expect(user.reload.show_mobile_tour).not_to be_nil
      expect(user.show_mobile_tour).to be true
    end
  end

  context 'show feed app tour by default' do

    it 'gives a default value of true' do
      user = FactoryBot.build :user, show_feed_tour: nil
      user.save!
      expect(user.reload.show_feed_tour).not_to be_nil
      expect(user.show_feed_tour).to be true
    end
  end

  context 'show entry app tour by default' do

    it 'gives a default value of true' do
      user = FactoryBot.build :user, show_entry_tour: nil
      user.save!
      expect(user.reload.show_entry_tour).not_to be_nil
      expect(user.show_entry_tour).to be true
    end
  end

  context 'show keyboard shortcuts app tour by default' do

    it 'gives a default value of true' do
      user = FactoryBot.build :user, show_kb_shortcuts_tour: nil
      user.save!
      expect(user.reload.show_kb_shortcuts_tour).not_to be_nil
      expect(user.show_kb_shortcuts_tour).to be true
    end
  end

  context 'subscriptions_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, subscriptions_updated_at: nil
      user.save!
      expect(user.reload.subscriptions_updated_at).not_to be_nil
      expect(user.subscriptions_updated_at).to eq date
    end
  end

  context 'folders_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, folders_updated_at: nil
      user.save!
      expect(user.reload.folders_updated_at).not_to be_nil
      expect(user.folders_updated_at).to eq date
    end
  end

  context 'refresh_feed_jobs_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, refresh_feed_jobs_updated_at: nil
      user.save!
      expect(user.reload.refresh_feed_jobs_updated_at).not_to be_nil
      expect(user.refresh_feed_jobs_updated_at).to eq date
    end
  end

  context 'subscribe_jobs_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, subscribe_jobs_updated_at: nil
      user.save!
      expect(user.reload.subscribe_jobs_updated_at).not_to be_nil
      expect(user.subscribe_jobs_updated_at).to eq date
    end
  end

  context 'config_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, config_updated_at: nil
      user.save!
      expect(user.reload.config_updated_at).not_to be_nil
      expect(user.config_updated_at).to eq date
    end
  end

  context 'user_data_updated_at defaults' do

    it 'defaults to md5 hash of current time' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      user = FactoryBot.build :user, user_data_updated_at: nil
      user.save!
      expect(user.reload.user_data_updated_at).not_to be_nil
      expect(user.user_data_updated_at).to eq date
    end
  end

  context 'confirmation reminder sent defaults' do

    it 'gives a default value of false to first reminder sent' do
      user = FactoryBot.build :user, first_confirmation_reminder_sent: nil
      user.save!
      expect(user.reload.first_confirmation_reminder_sent).not_to be_nil
      expect(user.first_confirmation_reminder_sent).to be false
    end

    it 'gives a default value of false to second reminder sent' do
      user = FactoryBot.build :user, second_confirmation_reminder_sent: nil
      user.save!
      expect(user.reload.second_confirmation_reminder_sent).not_to be_nil
      expect(user.second_confirmation_reminder_sent).to be false
    end
  end

  context 'keyboard shortcuts enabled defaults' do

    it 'enables keyboard shortcuts by default' do
      user = FactoryBot.build :user, kb_shortcuts_enabled: nil
      user.save!
      expect(user.reload.kb_shortcuts_enabled).not_to be_nil
      expect(user.reload.kb_shortcuts_enabled).to be true
    end
  end

end