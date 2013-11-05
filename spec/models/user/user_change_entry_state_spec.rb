require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
    @feed.entries << @entry1
  end

  context 'change entry state' do

    context 'single entry' do

      it 'marks entry as read' do
        @entry1.read_by?(@user).should be_false

        @user.change_entries_state @entry1, 'read'
        @entry1.read_by?(@user).should be_true
      end

      it 'marks entry as unread' do
        entry_state = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
        entry_state.read = true
        entry_state.save

        @user.change_entries_state @entry1, 'unread'
        @entry1.read_by?(@user).should be_false
      end

      it 'does not change an entry state if passed an unknown state' do
        @entry1.read_by?(@user).should be_false

        @user.change_entries_state @entry1, 'somethingsomethingsomething'
        @entry1.read_by?(@user).should be_false

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

        @entry1.read_by?(user2).should be_false
      end
    end

    context 'several entries' do

      before :each do
        @entry2 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 01, 01)
        @entry3 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
        @feed.entries << @entry2 << @entry3
      end

      context 'from a single feed' do

        it 'marks several entries as read' do
          @entry1.read_by?(@user).should be_false
          @entry2.read_by?(@user).should be_false
          @entry3.read_by?(@user).should be_false

          @user.change_entries_state @entry3, 'read', update_older: true

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

          @user.change_entries_state @entry3, 'unread', update_older: true

          @entry1.read_by?(@user).should be_false
          @entry2.read_by?(@user).should be_false
          @entry3.read_by?(@user).should be_false
        end

        it 'does not change state of newer entries from the same feed' do
          entry4 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry5 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry4 << entry5

          entry4.read_by?(@user).should be_false
          entry5.read_by?(@user).should be_false

          @user.change_entries_state @entry3, 'read', update_older: true

          entry4.read_by?(@user).should be_false
          entry5.read_by?(@user).should be_false
        end

        it 'does not change state of entries from other feeds' do
          feed2 = FactoryGirl.create :feed
          @user.subscribe feed2.fetch_url
          entry4 = FactoryGirl.build :entry, feed_id: feed2.id, published: Date.new(1975, 01, 01)
          feed2.entries << entry4

          entry4.read_by?(@user).should be_false

          @user.change_entries_state @entry3, 'read', update_older: true

          entry4.read_by?(@user).should be_false
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
        end

        it 'marks several entries as read' do
          @entry1.read_by?(@user).should be_false
          @entry2.read_by?(@user).should be_false
          @entry3.read_by?(@user).should be_false
          @entry4.read_by?(@user).should be_false
          @entry5.read_by?(@user).should be_false

          @user.change_entries_state @entry5, 'read', update_older: true, folder: @folder
          @entry1.read_by?(@user).should be_true
          @entry2.read_by?(@user).should be_true
          @entry3.read_by?(@user).should be_true
          @entry4.read_by?(@user).should be_true
          @entry5.read_by?(@user).should be_true
        end
      end

      context 'from all subscribed feeds' do

      end
    end

  end

end
