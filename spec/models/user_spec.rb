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
      @user.feeds << feed1 << feed2
      @user.feeds.include?(feed1).should be_true
      @user.feeds.include?(feed2).should be_true
    end

    it 'does not return feeds the user is not suscribed to' do
      feed = FactoryGirl.create :feed
      @user.feeds.include?(feed).should be_false
    end

    it 'does not allow subscribing to the same feed more than once' do
      feed = FactoryGirl.create :feed
      @user.feeds << feed
      @user.feeds << feed
      @user.feeds.count.should eq 1
      @user.feeds.first.should eq feed
    end
  end

  context 'relationship with folders' do
    it 'deletes folders when deleting a user' do
      folder1 = FactoryGirl.build :folder
      folder2 = FactoryGirl.build :folder
      @user.folders << folder1 << folder2

      Folder.count.should eq 2

      @user.destroy
      Folder.count.should eq 0
    end

    it 'does not allow associating to the same folder more than once' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      @user.folders << folder
      @user.folders.count.should eq 1
      @user.folders.first.should eq folder
    end
  end

  context 'relationship with entries' do
    it 'retrieves all entries for all subscribed feeds' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.feeds << feed1 << feed2
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

      @user.feeds << feed
      @user.entry_states.count.should eq 2
      @user.entry_states.where(entry_id: entry1.id, read: false).should be_present
      @user.entry_states.where(entry_id: entry2.id, read: false).should be_present
    end

    it 'removes entry states for all feed entries when unsubscribing from a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.feeds << feed

      @user.entry_states.count.should eq 2
      @user.feeds.delete feed
      @user.entry_states.count.should eq 0
    end

    it 'does not affect entry states for other feeds when unsubscribing from a feed' do
      feed1 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1
      feed2 = FactoryGirl.create :feed
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry2
      @user.feeds << feed1 << feed2

      @user.entry_states.count.should eq 2
      @user.feeds.delete feed1
      @user.entry_states.count.should eq 1
      @user.entry_states.where(user_id: @user.id, entry_id: entry2.id).should be_present
    end
  end

end
