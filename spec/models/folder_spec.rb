require 'spec_helper'

describe Folder do
  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder
    @user.folders << @folder
  end

  context 'validations' do
    it 'always belongs to a user' do
      folder = FactoryGirl.build :folder, user_id: nil
      folder.should_not be_valid
    end

    it 'requires a title' do
      folder_nil = FactoryGirl.build :folder, title: nil
      folder_nil.should_not be_valid

      folder_empty = FactoryGirl.build :folder, title: ''
      folder_empty.should_not be_valid
    end

    it 'does not accept duplicate titles for the same user' do
      folder_dupe = FactoryGirl.build :folder, user_id: @folder.user_id, title: @folder.title
      folder_dupe.should_not be_valid
    end

    it 'accepts duplicate titles for different users' do
      folder_dupe = FactoryGirl.build :folder, title: @folder.title
      folder_dupe.user_id.should_not eq @folder.user_id
      folder_dupe.should be_valid
    end
  end

  context 'association with feeds' do

    before :each do
      @feed1 = FactoryGirl.build :feed
      @feed2 = FactoryGirl.build :feed
      @feed3 = FactoryGirl.build :feed
      @folder.feeds << @feed1 << @feed2
    end

    it 'returns feeds associated with this folder' do
      @folder.feeds.should include @feed1
      @folder.feeds.should include @feed2
    end

    it 'does not return feeds not associated with this folder' do
      @folder.feeds.should_not include @feed3
    end
  end

  context 'association with entries' do
    it 'retrieves all entries for all feeds in a folder' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @folder.feeds << feed1 << feed2
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3

      @folder.entries.count.should eq 3
      @folder.entries.should include entry1
      @folder.entries.should include entry2
      @folder.entries.should include entry3
    end
  end

  context 'sanitization' do
    it 'sanitizes title' do
      title_unsanitized = '<script>alert("pwned!");</script>folder_title'
      title_sanitized = 'folder_title'
      folder = FactoryGirl.create :folder, title: title_unsanitized
      folder.title.should eq title_sanitized
    end
  end
end
