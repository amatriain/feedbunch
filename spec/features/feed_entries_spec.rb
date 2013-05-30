require 'spec_helper'

describe 'feed entries' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
    @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry1 << @entry2
    @user.feeds << @feed

    login_user_for_feature @user
    visit feeds_path
    read_feed @feed.id
  end

  it 'opens an entry', js: true do
    # Entry summary should not be visible
    page.should_not have_content @entry1.summary

    read_entry @entry1.id

    page.should have_content Nokogiri::HTML(@entry1.summary).text
  end

  it 'opens title link in a new tab', js: true do
    read_entry @entry1.id

    within "#entry-#{@entry1.id}-summary .entry-content .lead" do
      page.should have_css "a[target='_blank'][href='#{@entry1.url}']"
    end
  end

  it 'closes other entries when opening an entry', js: true do
    read_entry @entry1.id
    # Only summary of first entry should be visible
    page.should have_content Nokogiri::HTML(@entry1.summary).text
    page.should_not have_content Nokogiri::HTML(@entry2.summary).text
    read_entry @entry2.id
    # Only summary of second entry should be visible
    page.should_not have_content Nokogiri::HTML(@entry1.summary).text
    page.should have_content Nokogiri::HTML(@entry2.summary).text
  end

  it 'by default only shows unread entries in a feed', js: true do
    entry_state = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
    entry_state.read = true
    entry_state.save!

    read_feed @feed.id

    page.should have_content @entry2.title
    page.should_not have_content @entry1.title
  end

  it 'by default only shows unread entries in a folder', js: true do
    # @feed and feed2 are in a folder
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed2
    entry3 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry3
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed << feed2

    # @entry1 is read, @entry2 and entry3 are unread
    entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state1.read = true
    entry_state1.save!

    visit feeds_path
    read_folder folder.id

    page.should_not have_content @entry1.title
    page.should have_content @entry2.title
    page.should have_content entry3.title
  end

  it 'by default only shows unread entries when reading all subscriptions', js: true do
    # @feed is in a folder, feed2 isn't in any folder
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed2
    entry3 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry3
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed

    # @entry1 is read, @entry2 and entry3 are unread
    entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state1.read = true
    entry_state1.save!

    visit feeds_path
    read_folder 'all'

    page.should_not have_content @entry1.title
    page.should have_content @entry2.title
    page.should have_content entry3.title
  end

  it 'marks as read an entry when reading a feed and opening an entry', js: true do
    read_entry @entry1.id

    entry_state = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state.read.should be_true

    # On refresh, @entry1 should no longer appear
    visit feeds_path
    read_feed @feed.id
    page.should_not have_content @entry1.title
  end

  # Regression test for bug #177
  it 'marks as read an entry when reading a folder and opening an entry', js: true do
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed
    visit feeds_path

    read_folder folder.id
    read_entry @entry1.id

    # No alert should appear
    should_hide_alert 'problem-entry-state-change'

    entry_state = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state.read.should be_true

    # On refresh, @entry1 should no longer appear
    visit feeds_path
    read_feed @feed.id
    page.should_not have_content @entry1.title
  end

  it 'shows an alert if it cannot mark entry as read', js: true do
    User.any_instance.stub(:change_entry_state).and_raise StandardError.new
    read_entry @entry1.id

    should_show_alert 'problem-entry-state-change'
  end

  it 'marks all entries as read', js: true do
    mark_all_as_read

    entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state1.read.should be_true
    entry_state2 = EntryState.where(user_id: @user.id, entry_id: @entry2.id).first
    entry_state2.read.should be_true

    # On refresh, no entries should appear for @feed
    visit feeds_path
    read_feed @feed.id
    page.should_not have_content @entry1.title
    page.should_not have_content @entry2.title
    page.should_not have_css '[data-entry-id]'
  end

  it 'marks an entry as unread', js: true do
    read_entry @entry1.id
    entry_should_be_marked_read @entry1.id

    find("[data-unread-entry-id='#{@entry1.id}']").click

    entry_should_be_marked_unread @entry1.id

    read_feed @feed.id
    page.should_not have_content @entry1.title
  end

  it 'shows all entries, including read ones', js: true do
    entry_state1 = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
    entry_state1.read = true
    entry_state1.save!

    visit feeds_path
    read_feed @feed.id

    # @entry1 is read, should not appear on the page
    page.should_not have_content @entry1.title

    show_read_entries

    # both @entry1 and @entry2 should appear on the page
    page.should have_content @entry1.title
    page.should have_content @entry2.title

    # entries should have the correct CSS class
    page.should have_css "a[data-entry-id='#{@entry1.id}'].entry-read"
    page.should have_css "a[data-entry-id='#{@entry2.id}'].entry-unread"
  end

end