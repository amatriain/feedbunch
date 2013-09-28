require 'spec_helper'

describe User do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'without pagination' do

    before :each do
      @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << @entry1 << @entry2 << @entry3

      # Mark one of the three entries as read by user
      entry_state = EntryState.where(entry_id: @entry3.id, user_id: @user.id).first
      entry_state.read = true
      entry_state.save!
    end

    it 'retrieves unread entries in a feed' do
      entries = @user.feed_entries @feed
      entries.count.should eq 2
      entries.should include @entry1
      entries.should include @entry2
      entries.should_not include @entry3
    end

    it 'retrieves read and unread entries in a feed' do
      entries = @user.feed_entries @feed, include_read: true
      entries.count.should eq 3
      entries.should include @entry1
      entries.should include @entry2
      entries.should include @entry3
    end

  end

  context 'with pagination' do

    before :each do
      @entries = []
      # Ensure there are exactly 26 unread entries and 4 read entries
      Entry.all.each {|e| e.destroy}
      (0..29).each do |i|
        e = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2001, 01, 30-i)
        @feed.entries << e
        @entries << e
      end

      @user.change_entries_state @entries[26..29], 'read'
    end

    it 'retrieves first page of unread entries' do
      entries = @user.feed_entries @feed, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of unread entries' do
      entries = @user.feed_entries @feed, page: 2
      entries.count.should eq 1
      entries[0].should eq @entries[25]
    end

    it 'retrieves first page of all entries' do
      entries = @user.feed_entries @feed, include_read: true, page: 1
      entries.count.should eq 25
      entries.each_with_index do |entry, index|
        entry.should eq @entries[index]
      end
    end

    it 'retrieves last page of all entries' do
      entries = @user.feed_entries @feed, include_read: true, page: 2
      entries.count.should eq 5
      entries.each_with_index do |entry, index|
        entry.should eq @entries[25 + index]
      end
    end

  end
end
