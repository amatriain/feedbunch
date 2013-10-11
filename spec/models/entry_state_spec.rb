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

  context 'feed unread count' do

    it 'increments the cached unread count when creating an unread state' do
      entry_state = FactoryGirl.build :entry_state, read: false
      SubscriptionsManager.should_receive(:feed_increment_count).once.with do |feed, user|
        entry_state.entry.feed.should eq feed
        entry_state.user.should eq user
      end

      entry_state.save!
    end

    it 'does not increment the cached unread count when creating a read state' do
      entry_state = FactoryGirl.build :entry_state, read: true
      SubscriptionsManager.should_not_receive :feed_increment_count

      entry_state.save!
    end

    it 'decrements the cached unread count when deleting an unread state' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      user.feed_unread_count(feed).should eq 1

      entry_state = EntryState.where(entry_id: entry.id, user_id: user.id).first
      SubscriptionsManager.should_receive(:feed_increment_count).once.with do |feed_arg, user_arg, increment|
        entry_state.entry.feed.should eq feed_arg
        entry_state.user.should eq user_arg
        increment.should eq -1
      end

      entry_state.destroy
    end

    it 'does not decrement the cached unread count when deleting a read state' do
      entry_state = FactoryGirl.create :entry_state, read: true
      SubscriptionsManager.should_not_receive :feed_decrement_count

      entry_state.destroy
    end

    it 'increments the cached unread count when changing a state from read to unread' do
      entry_state = FactoryGirl.create :entry_state, read: true
      SubscriptionsManager.should_receive(:feed_increment_count).once.with do |feed, user|
        entry_state.entry.feed.should eq feed
        entry_state.user.should eq user
      end

      entry_state.read = false
      entry_state.save!
    end

    it 'decrements the cached unread count when changing a state from unread to read' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      entry.read_by?(user).should be_false
      user.feed_unread_count(feed).should eq 1

      entry_state = EntryState.where(entry_id: entry.id, user_id: user.id).first

      SubscriptionsManager.should_receive(:feed_increment_count).once.with do |feed_arg, user_arg, increment|
        entry_state.entry.feed.should eq feed_arg
        entry_state.user.should eq user_arg
        increment.should eq -1
      end

      entry_state.read = true
      entry_state.save!
    end

  end
end
