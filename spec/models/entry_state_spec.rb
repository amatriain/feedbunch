require 'spec_helper'

describe EntryState do

  before :each do
    @entry_state = FactoryGirl.create :entry_state
  end

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
      entry_state = FactoryGirl.create :entry_state
      entry_state_dupe = FactoryGirl.build :entry_state, entry_id: entry_state.entry.id, user_id: entry_state.user.id
      entry_state_dupe.should_not be_valid
    end

    it 'accepts multiple states for the same entry and different users' do
      user2 = FactoryGirl.create :user
      entry_state1 = FactoryGirl.create :entry_state
      entry_state2 = FactoryGirl.build :entry_state, entry_id: entry_state1.entry.id, user_id: user2.id
      entry_state2.should be_valid
    end

    it 'accepts multiple states for different entries and the same user' do
      entry2 = FactoryGirl.create :entry
      entry_state1 = FactoryGirl.create :entry_state
      entry_state2 = FactoryGirl.build :entry_state, entry_id: entry2.id, user_id: entry_state1.user.id
      entry_state2.should be_valid
    end
  end

  context 'callbacks' do

    it 'increments the cached count for all subscribed users when first saving it' do
      feed = FactoryGirl.create :feed
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      user1.unread_feed_entries_count(feed.id).should eq 0
      user2.unread_feed_entries_count(feed.id).should eq 0

      entry = FactoryGirl.build :entry, feed_id: feed.id
      entry.save!

      user1.unread_feed_entries_count(feed.id).should eq 1
      user2.unread_feed_entries_count(feed.id).should eq 1
    end

    it 'does not increment the cached count when updating an already saved entry' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.create :entry, feed_id: feed.id
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      user1.unread_feed_entries_count(feed.id).should eq 1
      user2.unread_feed_entries_count(feed.id).should eq 1

      entry.summary = "changed summary"
      entry.save!

      user1.unread_feed_entries_count(feed.id).should eq 1
      user2.unread_feed_entries_count(feed.id).should eq 1
    end

    it 'does not increment the cached count for unsubscribed users' do
      feed = FactoryGirl.create :feed
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url

      entry = FactoryGirl.build :entry, feed_id: feed.id
      entry.save!

      user1.unread_feed_entries_count(feed.id).should eq 1
      user2.unread_feed_entries_count(feed.id).should eq 0
    end

    it 'decrements the cached count when deleting an entry state' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      user.unread_feed_entries_count(feed.id).should eq 2

      entry1.destroy

      user.unread_feed_entries_count(feed.id).should eq 1
    end

  end
end
