require 'spec_helper'

describe EntryState do

  context 'validations' do

    it 'does not accept empty user' do
      entry_state = FactoryGirl.build :entry_state, user_id: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept empty entry' do
      entry_state = FactoryGirl.build :entry_state, entry_id: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept empty state' do
      entry_state = FactoryGirl.build :entry_state, read: nil
      entry_state.valid?.should be_false
    end

    it 'does not accept multiple states for the same entry and user' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      EntryState.exists?(entry_id: entry.id, user_id: user.id).should be_true

      entry_state_dupe = FactoryGirl.build :entry_state, entry_id: entry.id, user_id: user.id
      entry_state_dupe.should_not be_valid
    end

    it 'accepts multiple states for the same entry and different users' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user1 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2 = FactoryGirl.create :user
      user2.subscribe feed.fetch_url

      EntryState.exists?(entry_id: entry.id, user_id: user1.id).should be_true
      EntryState.exists?(entry_id: entry.id, user_id: user2.id).should be_true
    end

    it 'accepts multiple states for different entries and the same user' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      EntryState.exists?(entry_id: entry1.id, user_id: user.id).should be_true
      EntryState.exists?(entry_id: entry2.id, user_id: user.id).should be_true
    end
  end
end
