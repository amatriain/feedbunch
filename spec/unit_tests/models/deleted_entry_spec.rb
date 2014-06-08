require 'rails_helper'

describe DeletedEntry, type: :model do

  before :each do
    @deleted_entry = FactoryGirl.create :deleted_entry
  end

  context 'validations' do

    it 'always belongs to a feed' do
      deleted_entry = FactoryGirl.build :deleted_entry, feed_id: nil
      expect(deleted_entry).not_to be_valid
    end

    it 'does not accept duplicate guids for the same feed' do
      deleted_entry_dupe = FactoryGirl.build :deleted_entry, guid: @deleted_entry.guid, feed_id: @deleted_entry.feed.id
      expect(deleted_entry_dupe).not_to be_valid
    end

    it 'does accept duplicate guids for different feeds' do
      feed2 = FactoryGirl.create :feed
      deleted_entry_dupe = FactoryGirl.build :deleted_entry, guid: @deleted_entry.guid, feed_id: feed2.id
      expect(deleted_entry_dupe).to be_valid
    end

    it 'does not accept the same guid as an existing entry from the same feed' do
      entry = FactoryGirl.create :entry
      deleted_entry = FactoryGirl.build :deleted_entry, guid: entry.guid, feed_id: entry.feed_id
      expect(deleted_entry).not_to be_valid
    end

    it 'accepts the same guid as an existing entry from another feed' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.create :entry
      deleted_entry = FactoryGirl.build :deleted_entry, guid: entry.guid, feed_id: feed.id
      expect(deleted_entry).to be_valid
    end
  end

end
