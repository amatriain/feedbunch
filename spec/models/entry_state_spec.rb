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
      entry_state = FactoryGirl.create :entry_state, read: false
      SubscriptionsManager.should_receive(:feed_decrement_count).once.with do |feed, user|
        entry_state.entry.feed.should eq feed
        entry_state.user.should eq user
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
      entry_state = FactoryGirl.create :entry_state, read: false
      SubscriptionsManager.should_receive(:feed_decrement_count).once.with do |feed, user|
        entry_state.entry.feed.should eq feed
        entry_state.user.should eq user
      end

      entry_state.read = true
      entry_state.save!
    end

  end
end
