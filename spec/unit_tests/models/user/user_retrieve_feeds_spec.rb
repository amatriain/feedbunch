require 'spec_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'without pagination' do

    before :each do
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed

      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed3.id
      @feed1.entries << @entry1
      @feed2.entries << @entry2
      @feed3.entries << @entry3

      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url

      @user.change_entries_state @entry2, 'read'
    end

    it 'returns only feeds the user is suscribed to' do
      @user.subscribed_feeds.include?(@feed3).should be_false
    end

    it 'returns only feeds with unread entries' do
      feeds = @user.subscribed_feeds
      feeds.include?(@feed1).should be_true
      feeds.include?(@feed2).should be_false
    end

    it 'returns all feeds' do
      feeds = @user.subscribed_feeds include_read: true
      feeds.include?(@feed1).should be_true
      feeds.include?(@feed2).should be_true
    end

  end

  context 'with pagination' do

    before :each do
      @feeds = []
      # There are 26 feeds with unread entries and 4 without unread entries
      (0..25).each do |i|
        feed = FactoryGirl.create :feed, title: i.to_s.rjust(3,'0')
        entry = FactoryGirl.build :entry, feed_id: feed.id
        feed.entries << entry
        @user.subscribe feed.fetch_url
        @feeds << feed
      end
      (26..29).each do |i|
        feed = FactoryGirl.create :feed, title: i.to_s.rjust(3,'0')
        entry = FactoryGirl.build :entry, feed_id: feed.id
        feed.entries << entry
        @user.subscribe feed.fetch_url
        @user.change_entries_state entry, 'read'
        @feeds << feed
      end
    end

    it 'returns first page of unread feeds' do
      feeds = @user.subscribed_feeds page: 1
      feeds.count.should eq 25
      feeds.each_with_index do |feed, index|
        feed.should eq @feeds[index]
      end
    end

    it 'returns last page of unread feeds' do
      feeds = @user.subscribed_feeds page: 2
      feeds.count.should eq 1
      feeds[0].should eq @feeds[25]
    end

    it 'returns first page of all feeds' do
      feeds = @user.subscribed_feeds include_read: true, page: 1
      feeds.count.should eq 25
      feeds.each_with_index do |feed, index|
        feed.should eq @feeds[index]
      end
    end

    it 'returns last page of all feeds' do
      feeds = @user.subscribed_feeds include_read: true, page: 2
      feeds.count.should eq 5
      feeds.each_with_index do |feed, index|
        feed.should eq @feeds[25+index]
      end
    end

  end

  context 'feeds in a folder' do

    before :each do
      # @user is subscribed to @feed1, @feed2, @feed3, @feed4
      # @feed1 and @feed2 are in @folder.
      # @feed3 and @feed4 are not in any folder
      # @feed1 has @entry1, @feed3 has @entry3 (both entries are unread by @user)
      # @feed2 and @feed4 have no unread entries
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed
      @feed4 = FactoryGirl.create :feed
      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed3.id
      @feed1.entries << @entry1
      @feed3.entries << @entry3
      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url
      @user.subscribe @feed4.fetch_url
      @folder.feeds << @feed1 << @feed2
    end

    it 'returns feeds in a folder with unread entries' do
      feeds = @user.folder_feeds @folder
      feeds.count.should eq 1
      feeds.should include @feed1
    end

    it 'returns all feeds in a folder' do
      feeds = @user.folder_feeds @folder, include_read: true
      feeds.count.should eq 2
      feeds.should include @feed1
      feeds.should include @feed2
    end

    it 'returns feeds with unread entries which are not in any folder' do
      feeds = @user.folder_feeds Folder::NO_FOLDER
      feeds.count.should eq 1
      feeds.should include @feed3
    end

    it 'returns all feeds which are not in any folder' do
      feeds = @user.folder_feeds Folder::NO_FOLDER, include_read: true
      feeds.count.should eq 2
      feeds.should include @feed3
      feeds.should include @feed4
    end

    it 'raises an error if user does not own the folder' do
      folder = FactoryGirl.create :folder
      expect {@user.folder_feeds folder}.to raise_error FolderNotOwnedByUserError
    end

  end
end
