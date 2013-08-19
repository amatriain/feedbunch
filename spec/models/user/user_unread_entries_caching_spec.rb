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
        @user.change_entry_state [@entry2.id], 'read'
        unread_entries = @user.feed_unread_count @feed
        unread_entries.should eq 0
      end

      it 'increments feed cached count when marking an entry as unread' do
        @user.change_entry_state [@entry1.id], 'unread'
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

    context 'folder unread entries count' do

      it 'retrieves folder cached count' do
        unread_entries = @user.folder_unread_count @folder
        unread_entries.should eq 1
      end

      it 'retrieves cached count of all unread entries in all subscribed feeds' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3
        @user.subscribe feed2.fetch_url

        @user.folder_unread_count('all').should eq 2
      end

      it 'decrements folder cached count when marking an entry as read' do
        @folder.reload.unread_entries.should eq 1
        @user.change_entry_state [@entry2.id], 'read'
        @folder.reload.unread_entries.should eq 0
      end

      it 'increments folder cached count when marking an entry as unread' do
        @folder.reload.unread_entries.should eq 1
        @user.change_entry_state [@entry1.id], 'unread'
        @folder.reload.unread_entries.should eq 2
      end

      it 'increments folder cached count when adding entries to a feed' do
        @folder.reload.unread_entries.should eq 1

        entry3 = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry3

        @folder.reload.unread_entries.should eq 2
      end

      it 'decrements folder cached count when deleting unread entries from a feed' do
        @folder.reload.unread_entries.should eq 1

        @feed.entries.delete @entry2

        @folder.reload.unread_entries.should eq 0
      end

      it 'does not decrement folder cached count when deleting read entries from a feed' do
        @folder.reload.unread_entries.should eq 1

        @feed.entries.delete @entry1

        @folder.reload.unread_entries.should eq 1
      end

      it 'decrements folder cached count when unsubscribing from a feed' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3
        @user.subscribe feed2.fetch_url
        @folder.feeds << feed2

        @folder.reload.unread_entries.should eq 2

        @user.unsubscribe feed2

        @folder.reload.unread_entries.should eq 1
      end

      it 'increments folder cached count when adding a feed to a folder' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3
        @user.subscribe feed2.fetch_url

        @folder.reload.unread_entries.should eq 1

        @folder.feeds << feed2

        @folder.reload.unread_entries.should eq 2
      end

      it 'decrements folder cached count when removing a feed from a folder' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3
        @user.subscribe feed2.fetch_url
        @folder.feeds << feed2

        # @user should be subscribed to feed2, and it is inside @folder
        @user.feeds.include?(feed2).should be_true
        feed2.reload.user_folder(@user).should eq @folder
        @folder.reload.unread_entries.should eq 2

        @folder.feeds.delete feed2

        # @user should still be subscribed to feed2, but without being inside any folder
        @user.feeds.include?(feed2).should be_true
        feed2.user_folder(@user).should be_nil
        @folder.reload.unread_entries.should eq 1
      end
    end

    context 'user unread entries count' do

      it 'decrements user cached count when marking an entry as read' do
        @user.reload.unread_entries.should eq 1
        @user.change_entry_state [@entry2.id], 'read'
        @user.reload.unread_entries.should eq 0
      end

      it 'increments user cached count when marking an entry as unread' do
        @user.reload.unread_entries.should eq 1
        @user.change_entry_state [@entry1.id], 'unread'
        @user.reload.unread_entries.should eq 2
      end

      it 'increments user cached count when adding entries to a feed' do
        @user.reload.unread_entries.should eq 1

        entry3 = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry3

        @user.reload.unread_entries.should eq 2
      end

      it 'decrements user cached count when deleting unread entries from a feed' do
        @user.reload.unread_entries.should eq 1

        @feed.entries.delete @entry2

        @user.reload.unread_entries.should eq 0
      end

      it 'does not decrement user cached count when deleting read entries from a feed' do
        @user.reload.unread_entries.should eq 1

        @feed.entries.delete @entry1

        @user.reload.unread_entries.should eq 1
      end

      it 'increments user cached count when subscribing to a feed' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3

        @user.reload.unread_entries.should eq 1

        @user.subscribe feed2.fetch_url

        @user.reload.unread_entries.should eq 2
      end

      it 'decrements user cached count when unsubscribing from a feed' do
        feed2 = FactoryGirl.create :feed
        entry3 = FactoryGirl.build :entry, feed_id: feed2.id
        feed2.entries << entry3
        @user.subscribe feed2.fetch_url

        @user.reload.unread_entries.should eq 2

        @user.unsubscribe feed2

        @user.reload.unread_entries.should eq 1
      end

    end
  end

end
