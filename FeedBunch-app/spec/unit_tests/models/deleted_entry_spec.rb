# frozen_string_literal: true

require 'rails_helper'

describe DeletedEntry, type: :model do

  before :each do
    @deleted_entry = FactoryBot.create :deleted_entry
  end

  context 'validations' do

    it 'always belongs to a feed' do
      deleted_entry = FactoryBot.build :deleted_entry, feed_id: nil
      expect(deleted_entry).not_to be_valid
    end

    context 'guid' do
      it 'does not accept duplicate guids for the same feed' do
        deleted_entry_dupe = FactoryBot.build :deleted_entry, guid: @deleted_entry.guid, feed_id: @deleted_entry.feed.id
        expect(deleted_entry_dupe).not_to be_valid
      end

      it 'accepts duplicate guids for different feeds' do
        feed2 = FactoryBot.create :feed
        deleted_entry_dupe = FactoryBot.build :deleted_entry, guid: @deleted_entry.guid, feed_id: feed2.id
        expect(deleted_entry_dupe).to be_valid
      end

      it 'does not accept the same guid as an existing entry from the same feed' do
        entry = FactoryBot.create :entry
        deleted_entry = FactoryBot.build :deleted_entry, guid: entry.guid, feed_id: entry.feed_id
        expect(deleted_entry).not_to be_valid
      end

      it 'accepts the same guid as an existing entry from another feed' do
        feed = FactoryBot.create :feed
        entry = FactoryBot.create :entry
        deleted_entry = FactoryBot.build :deleted_entry, guid: entry.guid, feed_id: feed.id
        expect(deleted_entry).to be_valid
      end
    end

    context 'unique_hash' do
      it 'accepts deleted entries for the same feed with nil hash' do
        deleted_entry_nil_1 = FactoryBot.create :deleted_entry, unique_hash: nil
        expect(deleted_entry_nil_1).to be_valid

        deleted_entry_nil_2 = FactoryBot.build :deleted_entry, unique_hash: nil, feed_id: deleted_entry_nil_1.feed.id
        expect(deleted_entry_nil_2).to be_valid
      end

      it 'does not accept duplicate hashes for the same feed' do
        deleted_entry_dupe = FactoryBot.build :deleted_entry, unique_hash: @deleted_entry.unique_hash, feed_id: @deleted_entry.feed.id
        expect(deleted_entry_dupe).not_to be_valid
      end

      it 'accepts duplicate hashes for different feeds' do
        feed2 = FactoryBot.create :feed
        deleted_entry_dupe = FactoryBot.build :deleted_entry, unique_hash: @deleted_entry.unique_hash, feed_id: feed2.id
        expect(deleted_entry_dupe).to be_valid
      end

      it 'does not accept the same hash as an existing entry from the same feed' do
        entry = FactoryBot.create :entry
        deleted_entry = FactoryBot.build :deleted_entry, unique_hash: entry.unique_hash, feed_id: entry.feed_id
        expect(deleted_entry).not_to be_valid
      end

      it 'accepts the same hash as an existing entry from another feed' do
        feed = FactoryBot.create :feed
        entry = FactoryBot.create :entry
        deleted_entry = FactoryBot.build :deleted_entry, unique_hash: entry.unique_hash, feed_id: feed.id
        expect(deleted_entry).to be_valid
      end
    end
  end

end
