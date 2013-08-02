require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
    @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry1 << @entry2
    @user.subscribe @feed.fetch_url
    @user.change_entry_state [@entry1.id], 'read'
  end

  context 'unread entries count caching' do

    it 'retrieves feed cached count' do
      unread_entries = @user.unread_feed_entries_count @feed.id
      unread_entries.should eq 1
    end

    it 'retrieves folder cached count'

    it 'decrements feed cached count when marking an entry as read' do
      @user.change_entry_state [@entry2.id], 'read'
      unread_entries = @user.unread_feed_entries_count @feed.id
      unread_entries.should eq 0
    end

    it 'increments feed cached count when marking an entry as unread' do
      @user.change_entry_state [@entry1.id], 'unread'
      unread_entries = @user.unread_feed_entries_count @feed.id
      unread_entries.should eq 2
    end

    it 'increments feed cached count when adding entries to a feed'

    it 'decrements feed cached count when deleting unread entries from a feed'

    it 'does not decrement feed cached count when deleting read entries from a feed'

    it 'decrements folder cached count when marking an entry as read'

    it 'increments folder unread entries count when marking an entry as unread'

    it 'increments folder cached count when adding entries to a feed'

    it 'decrements folder cached count when deleting unread entries from a feed'

    it 'does not decrement folder cached count when deleting read entries from a feed'

    it 'removes feed cached count when unsubscribing from a feed' do
      @user.unsubscribe @feed.id
      @user.feed_subscriptions.where(feed_id: @feed.id).should_not be_present
    end

    it 'counts all entries as unread when subscribing to a feed' do
      feed2 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed2.id
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry1 << entry2
      @user.subscribe feed2.fetch_url

      unread_entries = @user.unread_feed_entries_count feed2.id
      unread_entries.should eq 2
    end

    it 'decrements folder unread entries count when unsubscribing from a feed'

    it 'increments folder unread entries count when adding a feed to a folder'

    it 'decrements folder unread entries count when removing a feed from a folder'
  end

end
