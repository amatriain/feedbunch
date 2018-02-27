require 'rails_helper'

describe 'quick reading mode', type: :feature do

  context 'mark entries open when scrolling' do

    before :each do
      @user = FactoryBot.create :user
      @feed = FactoryBot.create :feed

      @entries = []
      (0..49).each do |i|
        entry = FactoryBot.build :entry, feed_id: @feed.id, summary: "entry summary #{i}"
        @feed.entries << entry
        @entries << entry
      end

      @user.subscribe @feed.fetch_url

      login_user_for_feature @user
    end

    it 'does not enable quick reading mode by default', js: true do
      # Quick Reading checkbox should not be checked in edit registration page
      visit edit_user_registration_path
      expect(find('#user_quick_reading')).not_to be_checked

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
      expect(page).to have_text @entries[49].title
    end

    it 'enables quick reading mode', js: true do
      enable_quick_reading @user

      # Quick Reading checkbox should be checked in edit registration page
      visit edit_user_registration_path
      expect(find('#user_quick_reading')).to be_checked

      visit read_path
      read_feed @feed, @user

      # first entry of the list (the one created most recently) is unread
      entry_should_be_marked_unread @entries[49]

      # scroll down enough to hide the top entry
      page.execute_script "document.getElementById('entry-#{@entries[49].id}').scrollIntoView(true);"
      page.execute_script 'window.scrollBy(0,100)'
      # wait 0.5 seconds for entries to be marked as read, if quick reading were enabled
      sleep 0.5
      # scroll to top of page again
      page.execute_script "document.getElementById('entry-#{@entries[49].id}').scrollIntoView(true);"

      # first entry should be read
      entry_read = page.has_css? "a[data-entry-id='#{@entries[49].id}'].entry-read"
      entry_becoming_read = page.has_css? "a[data-entry-id='#{@entries[49].id}'].entry-becoming-read"
      expect(entry_read || entry_becoming_read).to be true
    end
  end

  context 'open all entries by default' do

    before :each do
      @user = FactoryBot.create :user
      @feed = FactoryBot.create :feed

      @entries = []
      (0..9).each do |i|
        entry = FactoryBot.build :entry, feed_id: @feed.id, summary: "entry summary #{i}<img id=\"entry-image\" src=\"http://feed.com/some_image_#{i}.jpg\" alt=\"some-image\">"
        @feed.entries << entry
        @entries << entry
      end

      @user.subscribe @feed.fetch_url

      login_user_for_feature @user
    end

    it 'does not open all entries by default', js: true do
      # Open All Entries checkbox should not be checked in edit registration page
      visit edit_user_registration_path
      expect(find('#user_open_all_entries')).not_to be_checked

      visit read_path
      read_feed @feed, @user

      # all entries should be closed
      (0..9).each do |i|
        entry_should_be_closed @entries[i]
      end
    end

    it 'opens all entries by default if user selects this option', js: true do
      enable_open_all_entries @user

      # Open All Entries checkbox should be checked in edit registration page
      visit edit_user_registration_path
      expect(find('#user_open_all_entries')).to be_checked

      visit read_path
      read_feed @feed, @user

      # all entries should be open
      (0..9).each do |i|
        entry_should_be_open @entries[i]
        expect(page).to have_text "entry summary #{i}"
      end
    end

    # regression test
    it 'closes an open entry', js: true do
      enable_open_all_entries @user
      read_feed @feed, @user
      close_entry @entries[0]

      # entry should still be in the list
      within "#feed-entries #entry-#{@entries[0].id}" do
        expect(page).to have_text @entries[0].title
      end
    end

    context 'lazy load images' do

      before :each do
        @spinner_url = '/images/Ajax-loader.gif'
        enable_open_all_entries @user
        read_feed @feed, @user
      end

      it 'loads images in entries initially inside the viewport', js: true do
        # @entries[9] is the most recent entry, so it will be first on the list (in the viewport at the start)
        expect(page).to have_css "#entry-#{@entries[9].id}-summary .entry-content img[src*='feed.com/some_image_9.jpg']", visible: false
      end

      it 'does not load images in entries outside the viewport', js: true do
        # @entries[0] is the oldest entry, so it will be last on the list (outside the viewport at the start)
        expect(page).to have_css "#entry-#{@entries[0].id}-summary .entry-content img[src='#{@spinner_url}'][data-src='http://feed.com/some_image_0.jpg']", visible: false
      end

      it 'loads images in entries when they are scrolled into the viewport', js: true do
        # scroll to bottom of page
        page.execute_script 'window.scrollBy(0,10000)'
        # @entries[0] is the oldest entry, so it will be last on the list (outside the viewport until the user scrolls down)
        expect(page).to have_css "#entry-#{@entries[0].id}-summary .entry-content img[src*='feed.com/some_image_0.jpg']", visible: false
      end
    end
  end

end