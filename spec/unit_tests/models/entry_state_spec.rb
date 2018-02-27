require 'rails_helper'

describe EntryState, type: :model do

  context 'validations' do

    it 'does not accept empty user' do
      entry_state = FactoryBot.build :entry_state, user_id: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept empty entry' do
      entry_state = FactoryBot.build :entry_state, entry_id: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept empty state' do
      entry_state = FactoryBot.build :entry_state, read: nil
      expect(entry_state.valid?).to be false
    end

    it 'does not accept multiple states for the same entry and user' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry.id, user_id: user.id)).to be true

      entry_state_dupe = FactoryBot.build :entry_state, entry_id: entry.id, user_id: user.id
      expect(entry_state_dupe).not_to be_valid
    end

    it 'accepts multiple states for the same entry and different users' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user1 = FactoryBot.create :user
      user1.subscribe feed.fetch_url
      user2 = FactoryBot.create :user
      user2.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry.id, user_id: user1.id)).to be true
      expect(EntryState.exists?(entry_id: entry.id, user_id: user2.id)).to be true
    end

    it 'accepts multiple states for different entries and the same user' do
      feed = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed.id
      entry2 = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url

      expect(EntryState.exists?(entry_id: entry1.id, user_id: user.id)).to be true
      expect(EntryState.exists?(entry_id: entry2.id, user_id: user.id)).to be true
    end
  end

  context 'default values' do

    it 'sets published attribute to the entry published date' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url

      # Just after EntryState is created, default published value is the same as that of its Entry
      expect(EntryState.where(entry_id: entry.id, user_id: user.id).first.published).to eq entry.reload.published

      # Even if other code tries to change the EntryState published value, it still has the same value as the Entry
      EntryState.where(entry_id: entry.id, user_id: user.id).first.update published: Time.zone.now - 10.years
      expect(EntryState.where(entry_id: entry.id, user_id: user.id).first.published).to eq entry.reload.published
    end

    it 'sets entry_created_at attribute to the entry created_at date' do
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryBot.create :user
      user.subscribe feed.fetch_url

      # Just after EntryState is created, default entry_created_at value is the same as that of its Entry
      expect(EntryState.where(entry_id: entry.id, user_id: user.id).first.entry_created_at).to eq entry.reload.created_at

      # Even if other code tries to change the EntryState entry_created_at value, it still has the same value as the Entry
      EntryState.where(entry_id: entry.id, user_id: user.id).first.update entry_created_at: Time.zone.now - 10.years
      expect(EntryState.where(entry_id: entry.id, user_id: user.id).first.entry_created_at).to eq entry.reload.created_at
    end
  end
end
