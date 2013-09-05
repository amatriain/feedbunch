require 'spec_helper'

describe 'refresh feeds' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @user.subscribe @feed1.fetch_url

    login_user_for_feature @user
    visit feeds_path
    read_feed @feed1.id
  end

  it 'refreshes a single feed', js: true do
    # Page should have current entries for the feed
    page.should have_content @entry1.title

    # Refresh feed
    entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
    FeedClient.should_receive(:fetch).with @feed1, anything
    @feed1.entries << entry2
    refresh_feed

    # Page should have the new entries for the feed
    page.should have_content @entry1.title
    page.should have_content entry2.title
  end

  it 'only shows unread entries when refreshing a single feed', js: true do
    entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << entry2
    # @entry1 is read, entry2 is unread
    entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
    entry_state1.read = true
    entry_state1.save!
    # When refreshing the feed, fetch the new unread entry3
    entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
    FeedClient.stub :fetch do
      @feed1.entries << entry3
    end

    read_feed @feed1.id
    refresh_feed

    # entry2 and entry3 should appear, @entry1 should not appear because it's already read
    page.should_not have_content @entry1.title
    page.should have_content entry2.title
    page.should have_content entry3.title
  end

  it 'shows an alert if there is a problem refreshing a feed', js: true do
    FeedClient.stub(:fetch).and_raise StandardError.new
    refresh_feed

    should_show_alert 'problem-refreshing'
  end

  # Regression test for bug #169
  it 'does not show an alert refreshing a feed without unread entries', js: true do
    FeedClient.stub :fetch
    entry_state = EntryState.where(entry_id: @entry1.id, user_id: @user.id).first
    entry_state.read=true
    entry_state.save

    refresh_feed

    should_hide_alert 'problem-refreshing'
  end

end