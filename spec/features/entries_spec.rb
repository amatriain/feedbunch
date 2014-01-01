require 'spec_helper'

describe 'feed entries' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed1 << @feed2
    login_user_for_feature @user
  end

  context 'without pagination' do

    before :each do
      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1 << @entry2
      @user.subscribe @feed1.fetch_url

      @entry3 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry3
      @user.subscribe @feed2.fetch_url

      visit read_path
      read_feed @feed1, @user
    end

    it 'displays feed title and entry title for each entry', js: true do
      read_folder 'all'

      within '#feed-entries' do
        within "#entry-#{@entry1.id}" do
          page.should have_text @feed1.title, visible: true
          page.should have_text @entry1.title, visible: true
        end

        within "#entry-#{@entry2.id}" do
          page.should have_text @feed1.title, visible: true
          page.should have_text @entry2.title, visible: true
        end

        within "#entry-#{@entry3.id}" do
          page.should have_text @feed2.title, visible: true
          page.should have_text @entry3.title, visible: true
        end
      end
    end

    it 'opens an entry', js: true do
      # Entry summary should not be visible
      page.should_not have_content @entry1.summary

      read_entry @entry1

      page.should have_content Nokogiri::HTML(@entry1.summary).text
    end

    it 'opens title link in a new tab', js: true do
      read_entry @entry1

      within "#entry-#{@entry1.id}-summary .entry-content .lead" do
        page.should have_css "a[target='_blank'][href='#{@entry1.url}']"
      end
    end

    it 'closes other entries when opening an entry', js: true do
      read_entry @entry1
      # Only summary of first entry should be visible
      page.should have_content Nokogiri::HTML(@entry1.summary).text
      page.should_not have_content Nokogiri::HTML(@entry2.summary).text
      read_entry @entry2
      # Only summary of second entry should be visible
      page.should_not have_content Nokogiri::HTML(@entry1.summary).text
      page.should have_content Nokogiri::HTML(@entry2.summary).text
    end

    it 'by default only shows unread entries in a feed', js: true do
      entry_state = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
      entry_state.read = true
      entry_state.save!

      read_feed @feed1, @user

      page.should have_content @entry2.title
      page.should_not have_content @entry1.title
    end

    it 'by default only shows unread entries in a folder', js: true do
      # @feed1 and @feed2 are in a folder
      # @entry1 is read, @entry2 and @entry3 are unread
      entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry1.id).first
      entry_state1.read = true
      entry_state1.save!

      visit read_path
      read_folder @folder

      page.should_not have_content @entry1.title
      page.should have_content @entry2.title
      page.should have_content @entry3.title
    end

    it 'by default only shows unread entries when reading all subscriptions', js: true do
      # @feed1 and @feed2 are in a folder, feed3 isn't in any folder
      feed3 = FactoryGirl.create :feed
      entry4 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry4
      @user.subscribe feed3.fetch_url

      # @entry1 is read, @entry2 @entry3 and entry4 are unread
      @user.change_entries_state @entry1, 'read'

      visit read_path
      read_folder 'all'

      page.should_not have_content @entry1.title
      page.should have_content @entry2.title
      page.should have_content @entry3.title
      page.should have_content entry4.title
    end

    it 'marks as read an entry when reading a feed and opening an entry', js: true do
      read_entry @entry1

      entry_should_be_marked_read @entry1

      # On refresh, @entry1 should no longer appear
      visit read_path
      read_feed @feed1, @user
      page.should_not have_content @entry1.title
    end

    # Regression test for bug #177
    it 'marks as read an entry when reading a folder and opening an entry', js: true do
      read_folder @folder
      read_entry @entry1

      # No alert should appear
      should_hide_alert 'problem-entry-state-change'

      entry_should_be_marked_read @entry1

      # On refresh, @entry1 should no longer appear
      visit read_path
      read_feed @feed1, @user
      page.should_not have_content @entry1.title
    end

    it 'shows an alert if it cannot mark entry as read', js: true do
      User.any_instance.stub(:change_entries_state).and_raise StandardError.new
      read_entry @entry1

      should_show_alert 'problem-entry-state-change'
    end

    it 'marks all feed entries as read', js: true do
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_feed_entries_should_eq @feed1, 0, @user
    end

    it 'marks all folder entries as read', js: true do
      read_folder @folder
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_folder_entries_should_eq @folder, 0
    end

    it 'marks all entries as read', js: true do
      read_folder 'all'
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_folder_entries_should_eq 'all', 0
    end

    it 'hides Read button for read entries', js: true do
      read_entry @entry1
      entry_should_be_marked_read @entry1
      page.should have_css "div[id='entry-#{@entry1.id}'] a[ng-click='unread_entry(entry)']"
      page.should_not have_css "div[id='entry-#{@entry1.id}'] a[ng-click='read_entry(entry)']"
    end

    it 'hides Unead button for unread entries', js: true do
      read_entry @entry1
      entry_should_be_marked_read @entry1
      find("div[id='entry-#{@entry1.id}'] a[ng-click='unread_entry(entry)']").click
      entry_should_be_marked_unread @entry1

      page.should_not have_css "div[id='entry-#{@entry1.id}'] a[ng-click='unread_entry(entry)']"
      page.should have_css "div[id='entry-#{@entry1.id}'] a[ng-click='read_entry(entry)']"
    end

    it 'marks an entry as unread', js: true do
      read_entry @entry1
      entry_should_be_marked_read @entry1

      find("div[id='entry-#{@entry1.id}'] a[ng-click='unread_entry(entry)']").click
      entry_should_be_marked_unread @entry1

      # entry should still be present when reloading feed entries
      read_feed @feed1, @user
      page.should have_content @entry1.title
    end

    it 'marks an entry as read', js: true do
      # mark entry as unread
      read_entry @entry1
      entry_should_be_marked_read @entry1
      find("div[id='entry-#{@entry1.id}'] a[ng-click='unread_entry(entry)']").click
      entry_should_be_marked_unread @entry1

      # mark entry as read using the entry buttonbar
      find("div[id='entry-#{@entry1.id}'] a[ng-click='read_entry(entry)']").click
      entry_should_be_marked_read @entry1

      # entry should not be present when reloading feed entries
      read_feed @feed1, @user
      page.should_not have_content @entry1.title
    end

    it 'shows all entries in a feed, including read ones', js: true do
      entry_state1 = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
      entry_state1.read = true
      entry_state1.save!

      visit read_path
      read_feed @feed1, @user

      # @entry1 is read, should not appear on the page
      page.should_not have_content @entry1.title
      page.should have_content @entry2.title

      show_read

      # both @entry1 and @entry2 should appear on the page
      page.should have_content @entry1.title
      page.should have_content @entry2.title

      # entries should have the correct CSS class
      page.should have_css "a[data-entry-id='#{@entry1.id}'].entry-read"
      page.should have_css "a[data-entry-id='#{@entry2.id}'].entry-unread"
    end

    it 'shows all entries in a folder, including read ones', js: true do
      entry_state1 = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
      entry_state1.read = true
      entry_state1.save!
      read_folder @folder

      # @entry1 is read, should not appear on the page
      page.should_not have_content @entry1.title
      page.should have_content @entry2.title

      show_read

      # both @entry1 and @entry2 should appear on the page
      page.should have_content @entry1.title
      page.should have_content @entry2.title

      # entries should have the correct CSS class
      page.should have_css "a[data-entry-id='#{@entry1.id}'].entry-read"
      page.should have_css "a[data-entry-id='#{@entry2.id}'].entry-unread"
    end

    it 'shows day, month and time for entries published in the current year', js: true do
      today = Date.new 2000, 01, 01
      Date.stub today: today
      @entry1.update published: DateTime.new(2000, 07, 07)
      read_feed @feed1, @user
      within "#entry-#{@entry1.id}" do
        page.should have_text '07 Jul 00:00'
      end
    end

    it 'shows day, month and year for entries published in a previous year', js: true do
      today = Date.new 2000, 01, 01
      Date.stub today: today
      @entry1.update published: DateTime.new(1999, 07, 07)
      read_feed @feed1, @user
      within "#entry-#{@entry1.id}" do
        page.should have_text '07 Jul 1999'
      end
    end

    context 'link to read feed' do

      it 'displays feed title in entry content', js: true do
        read_entry @entry1
        within "#entry-#{@entry1.id}-summary .entry-content .entry-feed-link" do
          page.should have_text @feed1.title
        end
      end

      it 'shows only entries from feed when clicking on it', js: true do
        read_folder @folder
        # entries from @feed1 and @feed2 should be visible
        entry_should_be_visible @entry1
        entry_should_be_visible @entry2
        entry_should_be_visible @entry3

        read_entry @entry1
        entry_should_be_marked_read @entry1
        find("#entry-#{@entry1.id}-summary .entry-content .entry-feed-link a").click

        # @feed1 should be selected for reading
        feed_should_be_selected @feed1

        # only entries from @feed1 should be visible
        entry_should_be_visible @entry1
        entry_should_be_visible @entry2
        entry_should_not_be_visible @entry3

        # @entry1 should be marked as unread again.
        entry_should_be_marked_unread @entry1
      end
    end
  end

  context 'infinite scroll' do

    before :each do
      @entries = []
      # Ensure there are exactly 26 unread entries and 4 read entries in @feed1
      Entry.all.each {|e| e.destroy}
      (0..29).each do |i|
        e = FactoryGirl.build :entry, feed_id: @feed1.id, published: Date.new(2001, 01, 30-i)
        @feed1.entries << e
        @entries << e
      end

      @user.subscribe @feed1.fetch_url

      (26..29).each do |i|
        @user.change_entries_state @entries[i], 'read'
      end

      # @feed2 has one unread entry
      @feed2 = FactoryGirl.create :feed
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id, published: Date.new(1990, 01, 01)
      @feed2.entries << @entry2
      @user.subscribe @feed2.fetch_url

      @folder.feeds << @feed1 << @feed2

      visit read_path
      read_feed @feed1, @user
    end

    it 'loads the first page of unread feed entries', js: true do
      (0..24).each do |i|
        page.should have_content @entries[i].title
      end
      (25..29).each do |i|
        page.should_not have_content @entries[i].title
      end
    end

    it 'loads the second page of unread feed entries when scrolling down', js: true do
      page.execute_script 'window.scrollTo(0,100000)'
      sleep 1
      (0..25).each do |i|
        page.should have_content @entries[i].title
      end
      (26..29).each do |i|
        page.should_not have_content @entries[i].title
      end
    end

    it 'loads the first page of all entries in a feed', js: true do
      show_read
      (0..24).each do |i|
        page.should have_content @entries[i].title
      end
      (25..29).each do |i|
        page.should_not have_content @entries[i].title
      end
    end

    it 'loads the second page of all entries in a feed when scrolling down', js: true do
      show_read
      page.execute_script 'window.scrollTo(0,100000)'
      sleep 1
      (0..29).each do |i|
        page.should have_content @entries[i].title
      end
    end

    it 'loads the first page of unread folder entries', js: true do
      read_folder @folder
      (0..24).each do |i|
        page.should have_content @entries[i].title
      end
      (25..29).each do |i|
        page.should_not have_content @entries[i].title
      end
      page.should_not have_content @entry2.title
    end

    it 'loads the second page of unread folder entries when scrolling down', js: true do
      read_folder @folder
      page.execute_script 'window.scrollTo(0,100000)'
      sleep 1
      (0..25).each do |i|
        page.should have_content @entries[i].title
      end
      (26..29).each do |i|
        page.should_not have_content @entries[i].title
      end
      page.should have_content @entry2.title
    end

    it 'loads the first page of all entries in a folder', js: true do
      read_folder @folder
      show_read
      (0..24).each do |i|
        page.should have_content @entries[i].title
      end
      (25..29).each do |i|
        page.should_not have_content @entries[i].title
      end
      page.should_not have_content @entry2.title
    end

    it 'loads the second page of all entries in a folder when scrolling down', js: true do
      read_folder @folder
      show_read
      page.execute_script 'window.scrollTo(0,100000)'
      sleep 1
      (0..29).each do |i|
        page.should have_content @entries[i].title
      end
      page.should have_content @entry2.title
    end

    it 'marks all feed entries as read', js: true do
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_feed_entries_should_eq @feed1, 0, @user
    end

    it 'marks all folder entries as read', js: true do
      read_folder @folder
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_folder_entries_should_eq @folder, 0
    end

    it 'marks all entries as read', js: true do
      read_folder 'all'
      mark_all_as_read

      page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
      unread_folder_entries_should_eq 'all', 0
    end

  end

end