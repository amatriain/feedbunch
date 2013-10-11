require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
    @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry1 << @entry2
    @user.subscribe @feed.fetch_url
    @user.change_entries_state @entry1, 'read'
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed
  end

  context 'unread entries count caching' do

    context 'feed unread entries count' do
      it 'retrieves feed cached count' do
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 1
      end

      it 'decrements feed cached count when marking an entry as read' do
        @user.change_entries_state @entry2, 'read'
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 0
      end

      it 'increments feed cached count when marking an entry as unread' do
        @user.change_entries_state @entry1, 'unread'
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 2
      end

      it 'increments feed cached count when adding entries to a feed' do
        entry3 = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry3
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 2
      end

      it 'decrements feed cached count when deleting unread entries from a feed' do
        @entry2.destroy
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 0
      end

      it 'does not decrement feed cached count when deleting read entries from a feed' do
        @entry1.destroy
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 1
      end

      it 'removes feed cached count when unsubscribing from a feed' do
        @user.unsubscribe @feed
        FeedSubscription.exists?(feed_id: @feed.id, user_id: @user.id).should be_false
      end

      it 'counts all entries as unread when subscribing to a feed' do
        feed2 = FactoryGirl.create :feed
        entry1 = FactoryGirl.build :entry, feed_id: feed2.id
        entry2 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry1 << entry2
        @user.subscribe feed2.fetch_url

        unread_entries = @user.feed_unread_count feed2
        unread_entries.should eq 2
      end

    end
  end
end