require 'spec_helper'

describe 'unread entries count' do

  before :each do
    @user = FactoryGirl.create :user

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder1

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @folder1.feeds << @feed1

    @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed1.entries << @entry1_1 << @entry1_2 << @entry1_3
    @feed2.entries << @entry2_1

    login_user_for_feature @user
    visit read_path
  end

  it 'shows total number of unread entries', js: true do
    unread_folder_entries_should_eq 'all', 4
  end

  it 'shows number of unread entries in a folder', js: true do
    unread_folder_entries_should_eq @folder1.id, 3
  end

  it 'shows number of unread entries in a single feed', js: true do
    unread_feed_entries_should_eq @feed1.id, 3
    unread_feed_entries_should_eq @feed2.id, 1
  end

  it 'updates number of unread entries when adding a feed to a newly created folder', js: true do
    @folder1.feeds << @feed2

    visit read_path
    title = 'New folder'
    move_feed_to_new_folder @feed1.id, title

    # Entry count in @folder1 should be updated
    unread_folder_entries_should_eq @folder1.id, 1

    # new folder should have the correct entry count
    new_folder = Folder.where(user_id: @user.id, title: title).first
    unread_folder_entries_should_eq new_folder.id, 3
  end

  it 'updates number of unread entries when moving a feed into an existing folder', js: true do
    # @folder1 has @feed1, @feed2. folder2 has feed3
    @folder1.feeds << @feed2

    folder2 = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder2
    feed3 = FactoryGirl.create :feed
    @user.subscribe feed3.fetch_url
    folder2.feeds << feed3

    visit read_path

    move_feed_to_folder @feed1.id, folder2.id

    # Entry count in @folder1 should be updated
    unread_folder_entries_should_eq @folder1.id, 1
    # Entry count in folder2 should be updated
    unread_folder_entries_should_eq folder2.id, 3
  end

  it 'updates number of unread entries when removing a feed from a folder', js: true do
    @folder1.feeds << @feed2

    visit read_path

    remove_feed_from_folder @feed1.id, @folder1.id

    unread_folder_entries_should_eq @folder1.id, 1
  end

  it 'updates number of unread entries when subscribing to a feed', js: true do
    feed = FactoryGirl.create :feed
    entry1 = FactoryGirl.build :entry, feed_id: feed.id
    entry2 = FactoryGirl.build :entry, feed_id: feed.id
    feed.entries << entry1 << entry2
    subscribe_feed feed.url
    unread_folder_entries_should_eq 'all', 6
    unread_feed_entries_should_eq feed.id, 2
  end

  it 'updates number of unread entries when unsubscribing from a feed', js: true do
    @folder1.feeds << @feed2

    visit read_path
    unsubscribe_feed @feed1.id
    unread_folder_entries_should_eq 'all', 1
    unread_folder_entries_should_eq @folder1.id, 1
  end

  it 'updates number of unread entries when refreshing a feed', js: true do
    read_feed @feed1.id
    User.any_instance.stub :refresh_feed do
      entry = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << entry
    end

    refresh_feed

    unread_folder_entries_should_eq 'all', 5
    unread_folder_entries_should_eq @folder1.id, 4
    unread_feed_entries_should_eq @feed1.id, 4
  end
end
