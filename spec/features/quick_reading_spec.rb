require 'spec_helper'

describe 'quick reading mode' do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed

    @entries = []
    (1..100).each do
      entry = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry
      @entries << entry
    end

    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
  end

  it 'does not enable quick reading mode by default', js: true do
    visit read_path
    read_feed @feed, @user
    # first entry of the list (the one created most recently) is unread
    page.should have_css "a[data-entry-id='#{@entries[99].id}'].entry-unread"
    # scroll to bottom of page
    page.execute_script 'window.scrollBy(0,10000)'
    # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
    sleep 0.5
    # scroll to top of page again
    page.execute_script 'window.scrollBy(0,-10000)'
    # first entry should still be unread
    page.should have_css "a[data-entry-id='#{@entries[99].id}'].entry-unread"
  end

  it 'enables quick reading mode', js: true do
    enable_quick_reading @user
    pending
  end

end