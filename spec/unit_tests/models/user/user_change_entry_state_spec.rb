require 'rails_helper'

describe User, type: :model do
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
        expect(@entry1.read_by?(@user)).to be false

        @user.change_entries_state @entry1, 'read'
        expect(@entry1.read_by?(@user)).to be true
      end

      it 'marks entry as unread' do
        entry_state = EntryState.find_by user_id: @user.id, entry_id: @entry1.id
        entry_state.read = true
        entry_state.save

        @user.change_entries_state @entry1, 'unread'
        expect(@entry1.read_by?(@user)).to be false
      end

      it 'does not change an entry state if passed an unknown state' do
        expect(@entry1.read_by?(@user)).to be false

        @user.change_entries_state @entry1, 'somethingsomethingsomething'
        expect(@entry1.read_by?(@user)).to be false

        entry_state = EntryState.find_by user_id: @user.id, entry_id: @entry1.id
        entry_state.read = true
        entry_state.save!

        @user.change_entries_state @entry1, 'somethingsomethingsomething'
        expect(@entry1.read_by?(@user)).to be true
      end

      it 'does not change state for other users' do
        user2 = FactoryGirl.create :user
        user2.subscribe @feed.fetch_url

        @user.change_entries_state @entry1, 'read'

        expect(@entry1.read_by?(user2)).to be false
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
          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          expect(@entry1.read_by?(@user)).to be true
          expect(@entry2.read_by?(@user)).to be true
          expect(@entry3.read_by?(@user)).to be true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.find_by user_id: @user.id, entry_id: @entry1.id
          entry_state1.read = true
          entry_state1.save!
          entry_state2 = EntryState.find_by user_id: @user.id, entry_id: @entry2.id
          entry_state2.read = true
          entry_state2.save!
          entry_state3 = EntryState.find_by user_id: @user.id, entry_id: @entry3.id
          entry_state3.read = true
          entry_state3.save!

          @user.change_entries_state @entry3, 'unread', whole_feed: true

          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false
        end

        it 'does not change state of newer entries from the same feed' do
          entry4 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry5 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry4 << entry5

          expect(entry4.read_by?(@user)).to be false
          expect(entry5.read_by?(@user)).to be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          expect(entry4.read_by?(@user)).to be false
          expect(entry5.read_by?(@user)).to be false
        end

        it 'does not change state of entries from other feeds' do
          feed2 = FactoryGirl.create :feed
          @user.subscribe feed2.fetch_url
          entry4 = FactoryGirl.build :entry, feed_id: feed2.id, published: Date.new(1975, 01, 01)
          feed2.entries << entry4

          expect(entry4.read_by?(@user)).to be false

          @user.change_entries_state @entry3, 'read', whole_feed: true

          expect(entry4.read_by?(@user)).to be false
        end

        it 'enqueues job to update the unread count for the feed' do
          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 0

          @user.change_entries_state @entry3, 'read', whole_feed: true

          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 1
          job = UpdateFeedUnreadCountWorker.jobs.first
          expect(job['class']).to eq 'UpdateFeedUnreadCountWorker'

          args = job['args']

          # Check the arguments passed to the job
          feed_id = args[0]
          expect(feed_id).to eq @feed.id
          user_id = args[1]
          expect(user_id).to eq @user.id
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
          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false
          expect(@entry4.read_by?(@user)).to be false
          expect(@entry5.read_by?(@user)).to be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          expect(@entry1.read_by?(@user)).to be true
          expect(@entry2.read_by?(@user)).to be true
          expect(@entry3.read_by?(@user)).to be true
          expect(@entry4.read_by?(@user)).to be true
          expect(@entry5.read_by?(@user)).to be true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.find_by user_id: @user.id, entry_id: @entry1.id
          entry_state1.read = true
          entry_state1.save!
          entry_state2 = EntryState.find_by user_id: @user.id, entry_id: @entry2.id
          entry_state2.read = true
          entry_state2.save!
          entry_state3 = EntryState.find_by user_id: @user.id, entry_id: @entry3.id
          entry_state3.read = true
          entry_state3.save!
          entry_state4 = EntryState.find_by user_id: @user.id, entry_id: @entry4.id
          entry_state4.read = true
          entry_state4.save!
          entry_state5 = EntryState.find_by user_id: @user.id, entry_id: @entry5.id
          entry_state5.read = true
          entry_state5.save!

          @user.change_entries_state @entry5, 'unread', whole_folder: true

          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false
          expect(@entry4.read_by?(@user)).to be false
          expect(@entry5.read_by?(@user)).to be false
        end

        it 'does not change state of newer entries in the same folder' do
          entry6 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry7 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry6
          @feed2.entries << entry7

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false
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

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false

          @user.change_entries_state @entry5, 'read', whole_folder: true

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false
        end

        it 'enqueues job to update the unread count for all feeds in the folder' do
          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 0

          @user.change_entries_state @entry5, 'read', whole_folder: true

          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 2

          job1 = UpdateFeedUnreadCountWorker.jobs[0]
          expect(job1['class']).to eq 'UpdateFeedUnreadCountWorker'
          args1 = job1['args']
          # Check the arguments passed to the job
          feed_id1 = args1[0]
          expect(feed_id1).to eq @feed.id
          user_id1 = args1[1]
          expect(user_id1).to eq @user.id

          job2 = UpdateFeedUnreadCountWorker.jobs[1]
          expect(job2['class']).to eq 'UpdateFeedUnreadCountWorker'
          args2 = job2['args']
          # Check the arguments passed to the job
          feed_id2 = args2[0]
          expect(feed_id2).to eq @feed2.id
          user_id2 = args2[1]
          expect(user_id2).to eq @user.id
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
        end

        it 'marks several entries as read' do
          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false
          expect(@entry4.read_by?(@user)).to be false
          expect(@entry5.read_by?(@user)).to be false

          @user.change_entries_state @entry5, 'read', all_entries: true

          expect(@entry1.read_by?(@user)).to be true
          expect(@entry2.read_by?(@user)).to be true
          expect(@entry3.read_by?(@user)).to be true
          expect(@entry4.read_by?(@user)).to be true
          expect(@entry5.read_by?(@user)).to be true
        end

        it 'marks several entries as unread' do
          entry_state1 = EntryState.find_by user_id: @user.id, entry_id: @entry1.id
          entry_state1.update read: true
          entry_state2 = EntryState.find_by user_id: @user.id, entry_id: @entry2.id
          entry_state2.update read: true
          entry_state3 = EntryState.find_by user_id: @user.id, entry_id: @entry3.id
          entry_state3.update read: true
          entry_state4 = EntryState.find_by user_id: @user.id, entry_id: @entry4.id
          entry_state4.update read: true
          entry_state5 = EntryState.find_by user_id: @user.id, entry_id: @entry5.id
          entry_state5.update read: true

          @user.change_entries_state @entry5, 'unread', all_entries: true

          expect(@entry1.read_by?(@user)).to be false
          expect(@entry2.read_by?(@user)).to be false
          expect(@entry3.read_by?(@user)).to be false
          expect(@entry4.read_by?(@user)).to be false
          expect(@entry5.read_by?(@user)).to be false
        end

        it 'does not change state of newer entries' do
          entry6 = FactoryGirl.build :entry, feed_id: @feed.id, published: Date.new(2010, 01, 01)
          entry7 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(2000, 12, 31)
          @feed.entries << entry6
          @feed2.entries << entry7

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false

          @user.change_entries_state @entry5, 'read', all_entries: true

          expect(entry6.read_by?(@user)).to be false
          expect(entry7.read_by?(@user)).to be false
        end

        it 'enqueues job to update the unread count for all feeds' do
          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 0

          @user.change_entries_state @entry5, 'read', all_entries: true

          expect(UpdateFeedUnreadCountWorker.jobs.size).to eq 2

          job1 = UpdateFeedUnreadCountWorker.jobs[0]
          expect(job1['class']).to eq 'UpdateFeedUnreadCountWorker'
          args1 = job1['args']
          # Check the arguments passed to the job
          feed_id1 = args1[0]
          expect(feed_id1).to eq @feed.id
          user_id1 = args1[1]
          expect(user_id1).to eq @user.id

          job2 = UpdateFeedUnreadCountWorker.jobs[1]
          expect(job2['class']).to eq 'UpdateFeedUnreadCountWorker'
          args2 = job2['args']
          # Check the arguments passed to the job
          feed_id2 = args2[0]
          expect(feed_id2).to eq @feed2.id
          user_id2 = args2[1]
          expect(user_id2).to eq @user.id
        end

      end
    end

  end

end
