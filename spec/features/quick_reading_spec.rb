require 'spec_helper'

describe 'quick reading mode' do

  context 'mark entries open when scrolling' do

    before :each do
      @user = FactoryGirl.create :user
      @feed = FactoryGirl.create :feed

      @entries = []
      (0..49).each do |i|
        entry = FactoryGirl.build :entry, feed_id: @feed.id, summary: "entry summary #{i}"
        @feed.entries << entry
        @entries << entry
      end

      @user.subscribe @feed.fetch_url

      login_user_for_feature @user

      page.driver.resize_window(800, 600)
    end

    it 'does not enable quick reading mode by default', js: true do
      # Quick Reading checkbox should not be checked in edit registration page
      visit edit_user_registration_path
      find('#user_quick_reading').should_not be_checked

      visit read_path
      read_feed @feed, @user

      # first entry of the list (the one created most recently) is unread
      entry_should_be_marked_unread @entries[49]

      # scroll to bottom of page
      page.execute_script 'window.scrollBy(0,10000)'
      # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
      sleep 0.5
      # scroll to top of page again
      page.execute_script 'window.scrollBy(0,-10000)'

      # first entry should still be unread
      entry_should_be_marked_unread @entries[49]
      # after refresh first entry should still be visible
      read_feed @feed, @user
      page.should have_text @entries[49].title
    end

    it 'enables quick reading mode', js: true do
      enable_quick_reading @user

      # Quick Reading checkbox should be checked in edit registration page
      visit edit_user_registration_path
      find('#user_quick_reading').should be_checked

      visit read_path
      read_feed @feed, @user

      # first entry of the list (the one created most recently) is unread
      entry_should_be_marked_unread @entries[49]

      # scroll down enough to hide the top entry
      page.execute_script "document.getElementById('entry-#{@entries[49].id}').scrollIntoView(true);"
      page.execute_script 'window.scrollBy(0,50)'
      # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
      sleep 0.5
      # scroll to top of page again
      page.execute_script "document.getElementById('entry-#{@entries[49].id}').scrollIntoView(true);"

      # first entry should be read
      entry_read = page.has_css? "a[data-entry-id='#{@entries[49].id}'].entry-read"
      entry_becoming_read = page.has_css? "a[data-entry-id='#{@entries[49].id}'].entry-becoming-read"
      (entry_read || entry_becoming_read).should be_true
    end
  end

  context 'open all entries by default' do

    before :each do
      @user = FactoryGirl.create :user
      @feed = FactoryGirl.create :feed

      @entries = []
      (0..9).each do |i|
        entry = FactoryGirl.build :entry, feed_id: @feed.id, summary: "entry summary #{i}"
        @feed.entries << entry
        @entries << entry
      end

      @user.subscribe @feed.fetch_url

      login_user_for_feature @user
    end

    it 'does not open all entries by default', js: true do
      # Open All Entries checkbox should not be checked in edit registration page
      visit edit_user_registration_path
      find('#user_open_all_entries').should_not be_checked

      visit read_path
      read_feed @feed, @user

      # all entries should be closed
      (0..9).each do |i|
        entry_should_be_closed @entries[i]
      end
    end

    it 'opens all entries by default if user selects this option', js: true do
      check_open_all_entries @user

      # Open All Entries checkbox should be checked in edit registration page
      visit edit_user_registration_path
      find('#user_open_all_entries').should be_checked

      visit read_path
      read_feed @feed, @user

      # all entries should be open
      (0..9).each do |i|
        entry_should_be_open @entries[i]
        page.should have_text "entry summary #{i}"
      end
    end
  end

  context 'lazy load images' do

    it 'does not load images in entries outside the viewport'

    it 'loads images in entries when they are scrolled into the viewport'
  end

end