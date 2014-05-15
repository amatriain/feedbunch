require 'spec_helper'

describe DeletedEntry do

  before :each do
    @deleted_entry = FactoryGirl.create :deleted_entry
  end

  context 'validations' do

    it 'always belongs to a feed' do
      deleted_entry = FactoryGirl.build :deleted_entry, feed_id: nil
      deleted_entry.should_not be_valid
    end

    it 'does not accept duplicate guids for the same feed' do
      deleted_entry_dupe = FactoryGirl.build :deleted_entry, guid: @deleted_entry.guid, feed_id: @deleted_entry.feed.id
      deleted_entry_dupe.should_not be_valid
    end

    it 'does accept duplicate guids for different feeds' do
      feed2 = FactoryGirl.create :feed
      deleted_entry_dupe = FactoryGirl.build :deleted_entry, guid: @deleted_entry.guid, feed_id: feed2.id
      deleted_entry_dupe.should be_valid
    end

    it 'does not accept the same guid as an existing entry from the same feed' do
      entry = FactoryGirl.create :entry
      deleted_entry = FactoryGirl.build :deleted_entry, guid: entry.guid, feed_id: entry.feed_id
      deleted_entry.should_not be_valid
    end

    it 'accepts the same guid as an existing entry from another feed' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.create :entry
      deleted_entry = FactoryGirl.build :deleted_entry, guid: entry.guid, feed_id: feed.id
      deleted_entry.should be_valid
    end
  end

end
