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

    before :each do
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed

      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry2

      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url

      entry_state2 = EntryState.where(user_id: @user.id, entry_id: @entry2.id).first
      entry_state2.update read: true

      feed_subscription2 = FeedSubscription.where(feed_id: @feed2.id, user_id: @user.id).first
      feed_subscription2.update unread_entries: 0
    end

    it 'returns feeds the user is suscribed to' do
      @user.feeds.include?(@feed1).should be_true
      @user.feeds.include?(@feed2).should be_true
    end

    it 'does not return feeds the user is not suscribed to' do
      @user.feeds.include?(@feed3).should be_false
    end

    it 'returns feeds with unread entries' do
      feeds = @user.unread_feeds
      feeds.include?(@feed1).should be_true
      feeds.include?(@feed2).should be_false
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

end