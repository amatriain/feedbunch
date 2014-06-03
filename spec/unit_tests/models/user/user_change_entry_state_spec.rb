require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
    @feed.entries << @entry1
  end

  context 'change entry state' do

    context 'single entry' do

      before :each do
        @user.subscribe @feed.fetch_url
      end

      it 'marks entry as read' do
        @entry1.read_by?(@user).should be false

        @user.change_entries_state @entry1, 'read'
        @entry1.read_by?(@user).should be_true
      end

      it 'marks entry as unread' do
        entry_state = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
        entry_state.read = true
        entry_state.save

        @user.change_entries_state @entry1, 'unread'
        @entry1.read_by?(@user).should be false
      end

      it 'does not change an entry state if passed an unknown state' do
        @entry1.read_by?(@user).should be false

        @user.change_entries_state @entry1, 'somethingsomethingsomething'
        @entry1.read_by?(@user).should be false

        entry_state = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
        entry_state.read = true
        entry_state.save!

        @user.change_entries_state @entry1, 'somethingsomethingsomething'
        @entry1.read_by?(@user).should be_true
      end

      it 'does not change state for other users' do
        user2 = FactoryGirl.create :user
        user2.subscribe @feed.fetch_url

        @user.change_entries_state @entry1, 'read'

        @entry1.read_by?(user2).should be false
      end
    end

    context 'several entries' do

      before :each do
        @entry2 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 01, 01)
        @entry3 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
        @feed.entries << @entry2 << @entry3
      end

      context 'from a single feed' do

        before :each do
          @user.subscribe @feed.fetch_url
        end

        it 'marks several entries as read' do
          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          @entry1.read_by?(@user).should be_true
          @entry2.read_by?(@user).should be_true
          @entry3.read_by?(@user).should be_true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
          entry_state1.read = true
          entry_state1.save!
          entry_state2 = EntryState.where(user_id: @user.id, entry_id: @entry2.id).first
          entry_state2.read = true
          entry_state2.save!
          entry_state3 = EntryState.where(user_id: @user.id, entry_id: @entry3.id).first
          entry_state3.read = true
          entry_state3.save!

          @user.change_entries_state @entry3, 'unread', whole_feed: true

          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false
        end

        it 'does not change state of newer entries from the same feed' do
          entry4 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry5 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry4 << entry5

          entry4.read_by?(@user).should be false
          entry5.read_by?(@user).should be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          entry4.read_by?(@user).should be false
          entry5.read_by?(@user).should be false
        end

        it 'does not change state of entries from other feeds' do
          feed2 = FactoryGirl.create :feed
          @user.subscribe feed2.fetch_url
          entry4 = FactoryGirl.build :entry, feed_id: feed2.id, published: Date.new(1975, 01, 01)
          feed2.entries << entry4

          entry4.read_by?(@user).should be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          entry4.read_by?(@user).should be false
        end

        it 'enqueues job to update the unread count for the feed' do
          Resque.should_receive(:enqueue).with UpdateFeedUnreadCountJob, @feed.id, @user.id

          @user.change_entries_state @entry3, 'read', whole_feed: true
        end
      end

      context 'from a single folder' do

        before :each do
          @feed2 = FactoryGirl.create :feed
          @user.subscribe @feed2.fetch_url
          @entry4 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 01, 01)
          @entry5 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed2.entries << @entry4 << @entry5
          @folder = FactoryGirl.build :folder, user_id: @user.id
          @user.folders << @folder
          @folder.feeds << @feed << @feed2

          @user.subscribe @feed.fetch_url
        end

        it 'marks several entries as read' do
          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false
          @entry4.read_by?(@user).should be false
          @entry5.read_by?(@user).should be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          @entry1.read_by?(@user).should be_true
          @entry2.read_by?(@user).should be_true
          @entry3.read_by?(@user).should be_true
          @entry4.read_by?(@user).should be_true
          @entry5.read_by?(@user).should be_true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
          entry_state1.read = true
          entry_state1.save!
          entry_state2 = EntryState.where(user_id: @user.id, entry_id: @entry2.id).first
          entry_state2.read = true
          entry_state2.save!
          entry_state3 = EntryState.where(user_id: @user.id, entry_id: @entry3.id).first
          entry_state3.read = true
          entry_state3.save!
          entry_state4 = EntryState.where(user_id: @user.id, entry_id: @entry4.id).first
          entry_state4.read = true
          entry_state4.save!
          entry_state5 = EntryState.where(user_id: @user.id, entry_id: @entry5.id).first
          entry_state5.read = true
          entry_state5.save!

          @user.change_entries_state @entry5, 'unread', whole_folder: true

          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false
          @entry4.read_by?(@user).should be false
          @entry5.read_by?(@user).should be false
        end

        it 'does not change state of newer entries in the same folder' do
          entry6 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry7 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry6
          @feed2.entries << entry7

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false
        end

        it 'does not change state of entries from other folders' do
          # @feed, @feed2 are in @folder. feed2 is in folder2, and feed3 is not in any folder.
          # @user is subscribed to all of them. feed2 and feed3 have one unread entry each.
          feed2 = FactoryGirl.create :feed
          @user.subscribe feed2.fetch_url
          feed3 = FactoryGirl.create :feed
          @user.subscribe feed3.fetch_url
          folder2 = FactoryGirl.build :folder, user_id: @user.id
          @user.folders << folder2
          folder2.feeds << feed2
          entry6 = FactoryGirl.build :entry, feed_id: feed2.id
          feed2.entries << entry6
          entry7 = FactoryGirl.build :entry, feed_id: feed3.id
          feed3.entries << entry7

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false
        end

        it 'enqueues job to update the unread count for all feeds in the folder' do
          Resque.should_receive(:enqueue).with UpdateFeedUnreadCountJob, @feed.id, @user.id
          Resque.should_receive(:enqueue).with UpdateFeedUnreadCountJob, @feed2.id, @user.id

          @user.change_entries_state @entry5, 'read', whole_folder: true
        end
      end

      context 'from all subscribed feeds' do

        before :each do
          @feed2 = FactoryGirl.create :feed
          @user.subscribe @feed2.fetch_url
          @entry4 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 01, 01)
          @entry5 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed2.entries << @entry4 << @entry5
          @folder = FactoryGirl.build :folder, user_id: @user.id
          @user.folders << @folder
          @folder.feeds << @feed

          @user.subscribe @feed.fetch_url
        end

        it 'marks several entries as read' do
          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false
          @entry4.read_by?(@user).should be false
          @entry5.read_by?(@user).should be false

          @user.change_entries_state @entry5, 'read', all_entries: true

          @entry1.read_by?(@user).should be_true
          @entry2.read_by?(@user).should be_true
          @entry3.read_by?(@user).should be_true
          @entry4.read_by?(@user).should be_true
          @entry5.read_by?(@user).should be_true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
          entry_state1.update read: true
          entry_state2 = EntryState.where(user_id: @user.id, entry_id: @entry2.id).first
          entry_state2.update read: true
          entry_state3 = EntryState.where(user_id: @user.id, entry_id: @entry3.id).first
          entry_state3.update read: true
          entry_state4 = EntryState.where(user_id: @user.id, entry_id: @entry4.id).first
          entry_state4.update read: true
          entry_state5 = EntryState.where(user_id: @user.id, entry_id: @entry5.id).first
          entry_state5.update read: true

          @user.change_entries_state @entry5, 'unread', all_entries: true

          @entry1.read_by?(@user).should be false
          @entry2.read_by?(@user).should be false
          @entry3.read_by?(@user).should be false
          @entry4.read_by?(@user).should be false
          @entry5.read_by?(@user).should be false
        end

        it 'does not change state of newer entries' do
          entry6 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry7 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry6
          @feed2.entries << entry7

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false

          @user.change_entries_state @entry5, 'read', all_entries: true

          entry6.read_by?(@user).should be false
          entry7.read_by?(@user).should be false
        end

        it 'enqueues job to update the unread count for all feeds' do
          Resque.should_receive(:enqueue).with UpdateFeedUnreadCountJob, @feed.id, @user.id
          Resque.should_receive(:enqueue).with UpdateFeedUnreadCountJob, @feed2.id, @user.id

          @user.change_entries_state @entry5, 'read', all_entries: true
        end

      end
    end

  end

end
