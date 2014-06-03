require 'spec_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed1

  end

  context 'without pagination' do

    before :each do
      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1 << @entry2 << @entry3

      @entry4 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry4

      # Mark one of the three @feed1 entries as read by user
      @user.change_entries_state @entry3, 'read'
    end

    it 'retrieves unread entries in a feed' do
      entries = @user.feed_entries @feed1
      entries.count.should eq 2
      entries.should include @entry1
      entries.should include @entry2
      entries.should_not include @entry3
    end

    it 'retrieves read and unread entries in a feed' do
      entries = @user.feed_entries @feed1, include_read: true
      entries.count.should eq 3
      entries.should include @entry1
      entries.should include @entry2
      entries.should include @entry3
    end

    it 'retrieves unread entries from a folder' do
      entries = @user.folder_entries @folder
      entries.count.should eq 2
      entries.should include @entry1
      entries.should include @entry2
    end

    it 'retrieves read and unread entries from a folder' do
      entries = @user.folder_entries @folder, include_read: true
      entries.count.should eq 3
      entries.should include @entry1
      entries.should include @entry2
      entries.should include @entry3
    end

    it 'retrieves unread entries for all subscribed feeds' do
      entries = @user.folder_entries 'all'
      entries.count.should eq 3
      entries.should include @entry1
      entries.should include @entry2
      entries.should include @entry4
    end

    it 'retrieves read and unread entries for all subscribed feeds' do
      entries = @user.folder_entries 'all', include_read: true
      entries.count.should eq 4
      entries.should include @entry1
      entries.should include @entry2
      entries.should include @entry3
      entries.should include @entry4
    end

  end

  context 'with pagination' do

    before :each do
      @entries = []
      # Ensure @feed1 has exactly 26 unread entries and 4 read entries
      Entry.all.each {|e| e.destroy}
      (0..29).each do |i|
        e = FactoryGirl.build :entry, feed_id: @feed1.id, published: Date.new(2001, 01, 30-i)
        @feed1.entries << e
        @entries << e
      end
      (26..29).each do |i|
        @user.change_entries_state @entries[i], 'read'
      end

      # @feed2 has 1 read and 1 unread entry
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
      @entry3 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 30)
      @feed2.entries << @entry2 << @entry3
      @user.change_entries_state @entry3, 'read'
      @entries << @entry2 << @entry3
    end

    it 'retrieves first page of unread entries in a feed' do
      entries = @user.feed_entries @feed1, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of unread entries in a feed' do
      entries = @user.feed_entries @feed1, page: 2
      entries.count.should eq 1
      entries[0].should eq @entries[25]
    end

    it 'retrieves first page of all entries in a feed' do
      entries = @user.feed_entries @feed1, include_read: true, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of all entries in a feed' do
      entries = @user.feed_entries @feed1, include_read: true, page: 2
      entries.count.should eq 5
      entries.each_with_index do |entry, index|
        entry.should eq @entries[25 + index]
      end
    end

    it 'retrieves first page of unread entries in all feeds' do
      entries = @user.folder_entries 'all', page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of unread entries in all feeds' do
      entries = @user.folder_entries 'all', page: 2
      entries.count.should eq 2
      entries[0].should eq @entries[25]
      entries[1].should eq @entry2
    end

    it 'retrieves first page of all entries in all feeds' do
      entries = @user.folder_entries 'all', include_read: true, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of all entries in all feeds' do
      entries = @user.folder_entries 'all', include_read: true, page: 2
      entries.count.should eq 7
      entries.each_with_index do |entry, index|
        entry.should eq @entries[25+index]
      end
    end

    it 'retrieves first page of unread entries in a folder' do
      entries = @user.folder_entries @folder, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of unread entries in a folder' do
      entries = @user.folder_entries @folder, page: 2
      entries.count.should eq 1
      entries[0].should eq @entries[25]
    end

    it 'retrieves first page of all entries in a folder' do
      entries = @user.folder_entries @folder, include_read: true, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of all entries in a folder' do
      entries = @user.folder_entries @folder, include_read: true, page: 2
      entries.count.should eq 5
      entries.each_with_index do |entry, index|
        entry.should eq @entries[25+index]
      end
    end

  end
end
