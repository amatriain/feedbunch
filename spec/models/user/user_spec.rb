require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do
    it 'does not allow duplicate usernames' do
      user_dupe = FactoryGirl.build :user, email: @user.email
      user_dupe.valid?.should be_false
    end
  end

  context 'relationship with feeds' do
    it 'returns feeds the user is suscribed to' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      @user.feeds.include?(feed1).should be_true
      @user.feeds.include?(feed2).should be_true
    end

    it 'does not return feeds the user is not suscribed to' do
      feed = FactoryGirl.create :feed
      @user.feeds.include?(feed).should be_false
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

    it 'retrieves unread entries from a folder' do
      # feed1 and feed2 are in @folder
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3
      @folder.feeds << feed1 << feed2

      # entry1 is read, entry2 and entry3 are unread
      entry_state1 = EntryState.where(user_id: @user.id, entry_id: entry1.id).first
      entry_state1.read = true
      entry_state1.save!

      entries = @user.unread_folder_entries @folder.id
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'retrieves unread entries for all subscribed feeds' do
      # feed1 is in @folder; feed2 is subscribed, but it's not in any folder
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3
      @folder.feeds << feed1

      # entry1 is read, entry2 and entry3 are unread
      entry_state1 = EntryState.where(user_id: @user.id, entry_id: entry1.id).first
      entry_state1.read = true
      entry_state1.save!

      entries = @user.unread_folder_entries 'all'
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to retrieve entries from a folder that does not belong to the user' do
      folder2 = FactoryGirl.create :folder
      expect{@user.unread_folder_entries folder2.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'relationship with entries' do
    it 'retrieves all entries for all subscribed feeds' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3

      @user.entries.count.should eq 3
      @user.entries.should include entry1
      @user.entries.should include entry2
      @user.entries.should include entry3
    end
  end

  context 'relationship with entry states' do
    it 'retrieves entry states for subscribed feeds' do
      entry_state1 = FactoryGirl.build :entry_state, user_id: @user.id
      entry_state2 = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state1
      @user.entry_states << entry_state2


      @user.entry_states.count.should eq 2
      @user.entry_states.should include entry_state1
      @user.entry_states.should include entry_state2
    end

    it 'deletes entry states when deleting a user' do
      entry_state = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state

      EntryState.count.should eq 1
      @user.destroy
      EntryState.count.should eq 0
    end

    it 'does not allow duplicate entry states' do
      entry_state = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state
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
      @user.unsubscribe feed.id
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
      @user.unsubscribe feed1.id
      @user.entry_states.count.should eq 1
      @user.entry_states.where(user_id: @user.id, entry_id: entry2.id).should be_present
    end

    it 'retrieves unread entries in a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      entry3 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2 << entry3
      @user.subscribe feed.fetch_url

      # Mark one of the three entries as read by user
      entry_state = EntryState.where(entry_id: entry3.id, user_id: @user.id).first
      entry_state.read = true
      entry_state.save!

      entries = @user.feed_entries feed.id
      entries.count.should eq 2
      entries.should include entry1
      entries.should include entry2
      entries.should_not include entry3
    end

    it 'retrieves read and unread entries in a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      entry3 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2 << entry3
      @user.subscribe feed.fetch_url

      # Mark one of the three entries as read by user
      entry_state = EntryState.where(entry_id: entry3.id, user_id: @user.id).first
      entry_state.read = true
      entry_state.save!

      entries = @user.feed_entries feed.id, true
      entries.count.should eq 3
      entries.should include entry1
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to retrieve unread entries from an unsubscribed feed' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry

      expect {@user.feed_entries feed.id}.to raise_error ActiveRecord::RecordNotFound
    end

  end

  context 'relationship with data_imports' do

    before :each do
      @data_import = FactoryGirl.build :data_import, user_id: @user.id
      @user.data_import = @data_import
    end

    it 'deletes data_imports when deleting a user' do
      DataImport.count.should eq 1
      @user.destroy
      DataImport.count.should eq 0
    end

    it 'deletes the old data_import when adding a new one for a user' do
      DataImport.exists?(@data_import).should be_true
      data_import2 = FactoryGirl.build :data_import, user_id: @user.id
      @user.data_import = data_import2

      DataImport.exists?(@data_import).should be_false
    end
  end

  context 'refresh feed' do
    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
    end

    it 'fetches a feed' do
      FeedClient.should_receive(:fetch).with @feed.id, anything
      @user.refresh_feed @feed.id
    end

    it 'returns unread entries from the feed' do
      # @user is subscribed to feed2, which has entries entry1, entry2
      feed2 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed2.id
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry1 << entry2
      @user.subscribe feed2.fetch_url
      # entry1 is read, entry2 is unread
      entry_state1 = EntryState.where(entry_id: entry1.id, user_id: @user.id).first
      entry_state1.read = true
      entry_state1.save!
      # fetches a new entry (unread by default)
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      FeedClient.stub :fetch do
        feed2.entries << entry3
        feed2
      end

      # refresh should return the "old" unread entry and the new (just fetched) entry
      entries = @user.refresh_feed feed2.id
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to refresh a feed the user is not subscribed to' do
      feed2 = FactoryGirl.create :feed
      expect {@user.refresh_feed feed2.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

end