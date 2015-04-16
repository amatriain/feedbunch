require 'rails_helper'

describe EntryState, type: :model do

  context 'validations' do

    it 'does not accept empty user' do
      entry_state = FactoryGirl.build :entry_state, user_id: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept empty entry' do
      entry_state = FactoryGirl.build :entry_state, entry_id: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept empty state' do
      entry_state = FactoryGirl.build :entry_state, read: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept multiple states for the same entry and user' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry.id, user_id: user.id)).to be true

      entry_state_dupe = FactoryGirl.build :entry_state, entry_id: entry.id, user_id: user.id
      expect(entry_state_dupe).not_to be_valid
    end

    it 'accepts multiple states for the same entry and different users' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user1 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2 = FactoryGirl.create :user
      user2.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry.id, user_id: user1.id)).to be true
      expect(EntryState.exists?(entry_id: entry.id, user_id: user2.id)).to be true
    end

    it 'accepts multiple states for different entries and the same user' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry1.id, user_id: user.id)).to be true
      expect(EntryState.exists?(entry_id: entry2.id, user_id: user.id)).to be true
    end
  end

  context 'default values' do

    it 'sets published attribute to the entry published date' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.where(entry_id: entry.id, user_id: user.id).first.published).to eq entry.published

      # TODO try to change EntryState instance published attribute, check that it is automatically
      # reset to the Entry published value.
    end
  end
end
