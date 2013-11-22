require 'spec_helper'

describe 'quick reading mode' do

  context 'mark entries open when scrolling' do

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

      page.driver.resize_window(800, 600)
    end

    it 'does not enable quick reading mode by default', js: true do
      # Quick Reading checkbox should not be checked in edit registration page
      visit edit_user_registration_path
      find('#user_quick_reading').should_not be_checked

      visit read_path
      read_feed @feed, @user

      # first entry of the list (the one created most recently) is unread
      entry_should_be_marked_unread @entries[99]

      # scroll to bottom of page
      page.execute_script 'window.scrollBy(0,10000)'
      # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
      sleep 0.5
      # scroll to top of page again
      page.execute_script 'window.scrollBy(0,-10000)'

      # first entry should still be unread
      entry_should_be_marked_unread @entries[99]
      # after refresh first entry should still be visible
      read_feed @feed, @user
      page.should have_text @entries[99].title
    end

    it 'enables quick reading mode', js: true do
      enable_quick_reading @user

      # Quick Reading checkbox should be checked in edit registration page
      visit edit_user_registration_path
      find('#user_quick_reading').should be_checked

      visit read_path
      read_feed @feed, @user

      # first entry of the list (the one created most recently) is unread
      entry_should_be_marked_unread @entries[99]

      # scroll down enough to hide the top entry
      page.execute_script "document.getElementById('entry-#{@entries[99].id}').scrollIntoView(true);"
      page.execute_script 'window.scrollBy(0,50)'
      # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
      sleep 0.5
      # scroll to top of page again
      page.execute_script "document.getElementById('entry-#{@entries[99].id}').scrollIntoView(true);"

      # first entry should be read
      entry_read = page.has_css? "a[data-entry-id='#{@entries[99].id}'].entry-read"
      entry_becoming_read = page.has_css? "a[data-entry-id='#{@entries[99].id}'].entry-becoming-read"
      (entry_read || entry_becoming_read).should be_true
      # after refresh first entry should not be visible
      read_feed @feed, @user
      page.should_not have_text @entries[99].title
    end
  end

end