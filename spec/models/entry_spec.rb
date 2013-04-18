require 'spec_helper'

describe Entry do

  before :each do
    @entry = FactoryGirl.create :entry
    @entry.should be_valid
  end

  context 'validations' do

    it 'always belong to a feed' do
      entry = FactoryGirl.build :entry, feed_id: nil
      entry.should_not be_valid
    end

    it 'requires a title' do
      entry_nil = FactoryGirl.build :entry, title: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, title: ''
      entry_empty.should_not be_valid
    end

    it 'requires a URL' do
      entry_nil = FactoryGirl.build :entry, url: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, url: ''
      entry_empty.should_not be_valid
    end

    it 'accepts valid URLs' do
      entry = FactoryGirl.build :entry, url: 'http://xkcd.com'
      entry.should be_valid
    end

    it 'does not accept invalid URLs' do
      entry = FactoryGirl.build :entry, url: 'not-a-url'
      entry.should_not be_valid
    end

    it 'requires a guid' do
      entry_nil = FactoryGirl.build :entry, guid: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, guid: ''
      entry_empty.should_not be_valid
    end

    it 'does not accept duplicate guids' do
      entry_dupe = FactoryGirl.build :entry, guid: @entry.guid
      entry_dupe.should_not be_valid
    end
  end
end
