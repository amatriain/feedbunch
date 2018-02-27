require 'rails_helper'

describe 'unread entries count', type: :feature do

  before :each do
    @user = FactoryBot.create :user

    # @user has @folder1
    @folder1 = FactoryBot.build :folder, user_id: @user.id
    @user.folders << @folder1

    @feed1 = FactoryBot.create :feed
    @feed2 = FactoryBot.create :feed

    # @feed1 has 3 unread entries, @feed2 has 1 unread entry
    @entry1_1 = FactoryBot.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryBot.build :entry, feed_id: @feed1.id
    @entry1_3 = FactoryBot.build :entry, feed_id: @feed1.id
    @entry2_1 = FactoryBot.build :entry, feed_id: @feed2.id
    @feed1.entries << @entry1_1 << @entry1_2 << @entry1_3
    @feed2.entries << @entry2_1

    # @user is subscribed to @feed1 and @feed2
    # @feed1 and @feed2 are in @folder1
    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @folder1.feeds << @feed1 << @feed2

    login_user_for_feature @user
    visit read_path
  end

  context 'initial unread counts' do

    it 'shows total number of unread entries', js: true do
      unread_folder_entries_should_eq 'all', 4
    end

    it 'shows number of unread entries in a folder', js: true do
      unread_folder_entries_should_eq @folder1, 4
    end

    it 'shows number of unread entries in a single feed', js: true do
      unread_feed_entries_should_eq @feed1, 3, @user
      unread_feed_entries_should_eq @feed2, 1, @user
    end
  end

  context 'moving feeds into and out of folders' do

    it 'updates number of unread entries when adding a feed to a newly created folder', js: true do
      title = 'New folder'
      move_feed_to_new_folder @feed1, title, @user

      # Entry count in @folder1 should be updated
      unread_folder_entries_should_eq @folder1, 1

      # new folder should have the correct entry count
      new_folder = Folder.find_by user_id: @user.id, title: title
      unread_folder_entries_should_eq new_folder, 3
    end

    it 'updates number of unread entries when moving a feed into an existing folder', js: true do
      folder2 = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder2
      feed3 = FactoryBot.create :feed
      @user.subscribe feed3.fetch_url
      folder2.feeds << feed3

      visit read_path

      move_feed_to_folder @feed1, folder2, @user

      # Entry count in @folder1 should be updated
      unread_folder_entries_should_eq @folder1, 1
      # Entry count in folder2 should be updated
      unread_folder_entries_should_eq folder2, 3
    end

    it 'updates number of unread entries when removing a feed from a folder', js: true do
      remove_feed_from_folder @feed1, @user

      unread_folder_entries_should_eq @folder1, 1
    end
  end

  context 'subscribing, unsubscribing, refreshing feeds' do

    it 'updates number of unread entries when subscribing to a feed', js: true do
      feed = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed.id
      entry2 = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      job_state = FactoryBot.build :subscribe_job_state, user_id: @user.id, fetch_url: feed.fetch_url

      allow_any_instance_of(User).to receive :enqueue_subscribe_job do |user|
        if user.id == @user.id
          user.subscribe_job_states << job_state
        end
      end

      allow_any_instance_of(User).to receive :find_subscribe_job_state do |user|
        if user.id == @user.id
          user.subscribe feed.fetch_url
          job_state.update state: SubscribeJobState::SUCCESS, feed_id: feed.id
          job_state
        end
      end

      subscribe_feed feed.url
      unread_folder_entries_should_eq 'all', 6
      unread_feed_entries_should_eq feed, 2, @user
    end

    it 'updates number of unread entries when unsubscribing from a feed', js: true do
      unsubscribe_feed @feed1, @user
      unread_folder_entries_should_eq 'all', 1
      unread_folder_entries_should_eq @folder1, 1
    end

    it 'updates number of unread entries when refreshing a feed', js: true do
      read_feed @feed1, @user
      allow_any_instance_of(User).to receive :refresh_feed do |user|
        if user.id == @user.id
          job_state = FactoryBot.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed1.id
          user.refresh_feed_job_states << job_state
        end
      end

      allow_any_instance_of(User).to receive :find_refresh_feed_job_state do |user|
        if user.id == @user.id
          FeedSubscription.find_by(user_id: @user.id, feed_id: @feed1.id).update unread_entries: 4
          job_state = RefreshFeedJobState.find_by user_id: user.id, feed_id: @feed1.id
          job_state.update state: RefreshFeedJobState::SUCCESS
          job_state
        end
      end

      refresh_feed

      expect(page).to have_text 'Feed refreshed successfully'
      unread_folder_entries_should_eq 'all', 5
      unread_folder_entries_should_eq @folder1, 5
      unread_feed_entries_should_eq @feed1, 4, @user
    end
  end

  context 'marking entries as read/unread' do

    it 'updates number of unread entries when marking an entry as read', js: true do
      read_feed @feed1, @user
      read_entry @entry1_1

      unread_folder_entries_should_eq 'all', 3
      unread_folder_entries_should_eq @folder1, 3
      unread_feed_entries_should_eq @feed1, 2, @user
      unread_feed_entries_should_eq @feed2, 1, @user
    end

    it 'updates number of unread entries when marking an entry as unread', js: true do
      read_feed @feed1, @user
      read_entry @entry1_1
      unread_entry @entry1_1

      unread_folder_entries_should_eq 'all', 4
      unread_folder_entries_should_eq @folder1, 4
      unread_feed_entries_should_eq @feed1, 3, @user
      unread_feed_entries_should_eq @feed2, 1, @user
    end

    it 'sets total number of unread entries to zero when marking all as read', js: true do
      sleep 0.25
      read_folder 'all'
      expect(page).to have_text @entry1_1.title
      expect(page).to have_text @entry1_2.title
      expect(page).to have_text @entry1_3.title
      expect(page).to have_text @entry2_1.title
      mark_all_as_read

      unread_folder_entries_should_eq 'all', 0
    end

    it 'sets number of unread entries in a folder to zero when marking all as read', js: true do
      read_folder @folder1
      mark_all_as_read

      unread_folder_entries_should_eq @folder1, 0
    end

    it 'sets number of unread entries in a feed to zero when marking all as read', js: true do
      read_feed @feed1, @user
      mark_all_as_read

      unread_feed_entries_should_eq @feed1, 0, @user
    end

    it 'does not show a negative unread count', js: true do
      # @feed2 has an erroneous unread_entries value of 0, but it actually has one unread entry
      @user.unsubscribe @feed1
      FeedSubscription.find_by(user_id: @user.id, feed_id: @feed2.id).update unread_entries: 0
      visit read_path
      show_read

      # All unread counts should be 0
      unread_folder_entries_should_eq 'all', 0
      unread_folder_entries_should_eq @folder1, 0
      unread_feed_entries_should_eq @feed2, 0, @user

      # Open entry, marking it as read
      read_feed @feed2, @user
      read_entry @entry2_1

      # All unread counts should still be 0
      unread_folder_entries_should_eq 'all', 0
      unread_folder_entries_should_eq @folder1, 0
      unread_feed_entries_should_eq @feed2, 0, @user
    end

  end

  context 'reading folders' do

    context 'clicking on All Subscriptions link under a folder' do

      it 'updates unread counts', js: true do
        read_folder @folder1
        unread_feed_entries_should_eq @feed1, 3, @user
        unread_feed_entries_should_eq @feed2, 1, @user
        unread_folder_entries_should_eq @folder1, 4

        # Add 1 entry to @feed1 and another entry to @feed2
        entry1_4 = FactoryBot.build :entry, feed_id: @feed1.id
        @feed1.entries << entry1_4
        feed_subscription_1 = FeedSubscription.find_by user_id: @user.id, feed_id: @feed1.id
        feed_subscription_1.update unread_entries: (feed_subscription_1.unread_entries + 1)
        entry2_2 = FactoryBot.build :entry, feed_id: @feed2.id
        @feed2.entries << entry2_2
        feed_subscription_2= FeedSubscription.find_by user_id: @user.id, feed_id: @feed2.id
        feed_subscription_2.update unread_entries: (feed_subscription_2.unread_entries + 1)

        read_folder @folder1
        unread_feed_entries_should_eq @feed1, 4, @user
        unread_feed_entries_should_eq @feed2, 2, @user
        unread_folder_entries_should_eq @folder1, 6

        # Mark @feed1 entries as read
        EntryState.where(user_id: @user.id, entry_id: [@entry1_1.id, @entry1_2.id, @entry1_3.id, entry1_4.id]).
                    each {|es| es.update read: true}
        FeedSubscription.find_by(user_id: @user.id, feed_id: @feed1.id).update unread_entries: 0

        read_folder @folder1
        unread_feed_entries_should_eq @feed1, 0, @user
        unread_feed_entries_should_eq @feed2, 2, @user
        unread_folder_entries_should_eq @folder1, 2

        # Mark @feed2 entries as read
        EntryState.where(user_id: @user.id, entry_id: [@entry2_1.id, entry2_2.id]).
                    each {|es| es.update read: true}
        FeedSubscription.find_by(user_id: @user.id, feed_id: @feed2.id).update unread_entries: 0

        read_folder @folder1
        unread_feed_entries_should_eq @feed1, 0, @user
        unread_feed_entries_should_eq @feed2, 0, @user
        unread_folder_entries_should_eq @folder1, 0
      end
    end

    context 'clicking on All Subscriptions link for all subscribed feeds' do

      before :each do
        # Remove @feed1 from its folders for this test context.
        remove_feed_from_folder @feed1, @user
      end

      it 'updates unread counts', js: true do
        read_folder 'all'
        unread_feed_entries_should_eq @feed1, 3, @user
        unread_feed_entries_should_eq @feed2, 1, @user
        unread_folder_entries_should_eq 'all', 4
        unread_folder_entries_should_eq @folder1, 1

        # Add 1 entry to @feed1 and another entry to @feed2
        entry1_4 = FactoryBot.build :entry, feed_id: @feed1.id
        @feed1.entries << entry1_4
        feed_subscription_1 = FeedSubscription.find_by user_id: @user.id, feed_id: @feed1.id
        feed_subscription_1.update unread_entries: (feed_subscription_1.unread_entries + 1)
        entry2_2 = FactoryBot.build :entry, feed_id: @feed2.id
        @feed2.entries << entry2_2
        feed_subscription_2= FeedSubscription.find_by user_id: @user.id, feed_id: @feed2.id
        feed_subscription_2.update unread_entries: (feed_subscription_2.unread_entries + 1)

        read_folder 'all'
        unread_feed_entries_should_eq @feed1, 4, @user
        unread_feed_entries_should_eq @feed2, 2, @user
        unread_folder_entries_should_eq 'all', 6
        unread_folder_entries_should_eq @folder1, 2

        # Mark @feed1 entries as read
        EntryState.where(user_id: @user.id, entry_id: [@entry1_1.id, @entry1_2.id, @entry1_3.id, entry1_4.id]).
          each {|es| es.update read: true}
        FeedSubscription.find_by(user_id: @user.id, feed_id: @feed1.id).update unread_entries: 0

        read_folder 'all'
        unread_feed_entries_should_eq @feed1, 0, @user
        unread_feed_entries_should_eq @feed2, 2, @user
        unread_folder_entries_should_eq 'all', 2
        unread_folder_entries_should_eq @folder1, 2

        # Mark @feed2 entries as read
        EntryState.where(user_id: @user.id, entry_id: [@entry2_1.id, entry2_2.id]).
          each {|es| es.update read: true}
        FeedSubscription.find_by(user_id: @user.id, feed_id: @feed2.id).update unread_entries: 0

        read_folder 'all'
        unread_folder_entries_should_eq 'all', 0
      end
    end
  end

end
