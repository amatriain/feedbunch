require 'rails_helper'

describe 'keyboard shortcuts', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed

    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id, published: Time.zone.parse('2000-10-10')
    @entry2 = FactoryGirl.build :entry, feed_id: @feed1.id, published: Time.zone.parse('2000-01-01')
    @feed1.entries << @entry1 << @entry2

    @user.subscribe @feed1.fetch_url

    login_user_for_feature @user
  end

  context 'entries shortcuts' do

    before :each do
      read_feed @feed1, @user
    end

    it 'highlights first entry by default', js: true do
      skip
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
    end

    it 'moves up and down the list', js: true do
      skip
      # first entry is highlighted
      entry_should_be_highlighted @entry1

      # Move down
      press_key Feedbunch::Application.config.kb_entries_down

      entry_should_not_be_highlighted @entry1
      entry_should_be_highlighted @entry2

      # Move up
      press_key Feedbunch::Application.config.kb_entries_up

      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
    end

    it 'opens and closes entry', js: true do
      skip
      # first entry is highlighted and closed
      entry_should_be_highlighted @entry1
      entry_should_be_closed @entry1

      # open entry
      press_key Feedbunch::Application.config.kb_toggle_open_entry
      entry_should_be_open @entry1

      # close entry
      press_key Feedbunch::Application.config.kb_toggle_open_entry
      entry_should_be_closed @entry1
    end
  end

  context 'sidebar shortcuts' do

    before :each do
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed

      @entry3 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry3
      @entry4 = FactoryGirl.build :entry, feed_id: @feed3.id
      @feed3.entries << @entry4

      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url

      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder

      @folder.feeds << @feed2 << @feed3

      visit read_path
    end

    it 'highlights start link by default', js: true do
      skip
      start_link_should_be_highlighted
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3
    end

    it 'moves up and down the sidebar', js: true do
      skip
      # move down to "read all" link
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      start_link_should_not_be_highlighted
      folder_link_should_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_closed @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move down to @feed1 link
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_closed @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move down to @folder "read all" link
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move down to @feed2 link
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move up to @folder "read all" link
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move up to @feed link
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move up to "read all" link
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      start_link_should_not_be_highlighted
      folder_link_should_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3

      # move up to "start" link
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      start_link_should_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
      folder_link_should_not_be_highlighted @folder
      folder_should_be_open @folder
      feed_link_should_not_be_highlighted @feed2
      feed_link_should_not_be_highlighted @feed3
    end

    it 'selects links for reading', js: true do
      skip
      # read all entries
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      press_key Feedbunch::Application.config.kb_select_sidebar_link
      expect(page).to have_text @entry1.title
      expect(page).to have_text @entry2.title
      expect(page).to have_text @entry3.title
      expect(page).to have_text @entry4.title

      # show start page
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      press_key Feedbunch::Application.config.kb_select_sidebar_link
      expect(page).to have_css '#start-info'

      # read @feed1
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      press_key Feedbunch::Application.config.kb_select_sidebar_link
      expect(page).to have_text @entry1.title
      expect(page).to have_text @entry2.title

      # read @folder
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      press_key Feedbunch::Application.config.kb_select_sidebar_link
      expect(page).to have_text @entry3.title
      expect(page).to have_text @entry4.title
    end
  end

  context 'show/hide read entries shortcut' do

    before :each do
      # @feed1 has two entries, @entry1 (read) and @entry2 (unread)
      es = EntryState.where(entry_id: @entry1.id, user_id: @user.id).first
      es.update read: true
      s = FeedSubscription.where(feed_id: @feed1.id, user_id: @user.id).first
      s.update unread_entries: 1

      # @feed4 has one entry, @entry5 (read)
      @feed4 = FactoryGirl.create :feed
      @entry5 = FactoryGirl.build :entry, feed_id: @feed4.id
      @feed4.entries << @entry5
      @user.subscribe @feed4.fetch_url
      es2 = EntryState.where(entry_id: @entry5.id, user_id: @user.id).first
      es2.update read: true
      s = FeedSubscription.where(feed_id: @feed4.id, user_id: @user.id).first
      s.update unread_entries: 0

      visit read_path
    end

    it 'shows and hides read entries', js: true do
      # @entry1 is read, so it isn't visible by default
      expect(page).to have_text @feed1.title
      read_feed @feed1, @user
      expect(page).not_to have_text @entry1.title
      expect(page).to have_text @entry2.title

      # @feed4 has no unread entries, so it isn't visible by default
      expect(page).not_to have_text @feed4.title

      # show read entries
      press_key Feedbunch::Application.config.kb_toggle_show_read
      expect(page).to have_text @feed1.title
      expect(page).to have_text @entry1.title
      expect(page).to have_text @entry2.title
      expect(page).to have_text @feed4.title

      # Hide read entries
      press_key Feedbunch::Application.config.kb_toggle_show_read
      expect(page).to have_text @feed1.title
      expect(page).not_to have_text @entry1.title
      expect(page).to have_text @entry2.title
      expect(page).not_to have_text @feed4.title
    end
  end

  context 'mark all entries as read' do

    it 'marks all entries as read', js: true do
      read_feed @feed1, @user
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2

      press_key Feedbunch::Application.config.kb_mark_all_read

      expect(page).to have_text @entry1.title
      entry_should_be_marked_read @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_read @entry2

      read_feed @feed1, @user
      expect(page).not_to have_text @entry1.title
      expect(page).not_to have_text @entry2.title
    end
  end

  context 'toggle read/unread entry' do

    it 'marks entry as read', js: true do
      skip
      read_feed @feed1, @user
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2

      # mark @entry1 read
      press_key Feedbunch::Application.config.kb_toggle_read_entry
      entry_should_be_marked_read @entry1

      read_feed @feed1, @user
      expect(page).not_to have_text @entry1.title
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2
    end

    it 'marks entry as unread', js: true do
      skip
      es = EntryState.where(entry_id: @entry1.id, user_id: @user.id).first
      es.update read: true

      read_feed @feed1, @user
      expect(page).not_to have_text @entry1.title
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2

      show_read

      expect(page).to have_text @entry1.title
      entry_should_be_marked_read @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2

      # mark @entry1 unread
      press_key Feedbunch::Application.config.kb_toggle_read_entry
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2

      read_feed @feed1, @user
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2
    end
  end

  context 'keyboard shortcuts configuration' do

    it 'disables keyboard shortcuts', js: true do
      skip
      disable_kb_shortcuts @user
      read_feed @feed1, @user

      # Entry navigation shortcuts should be disabled
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
      press_key Feedbunch::Application.config.kb_entries_down
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2

      # Sidebar navigation shortcuts should be disabled
      feed_link_should_be_highlighted @feed1
      press_key Feedbunch::Application.config.kb_sidebar_link_down
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_be_highlighted @feed1
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      start_link_should_not_be_highlighted
      folder_link_should_not_be_highlighted 'none'
      feed_link_should_be_highlighted @feed1

      # Mark all as read shortcut should be disabled
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2
      press_key Feedbunch::Application.config.kb_mark_all_read
      expect(page).to have_text @entry1.title
      entry_should_be_marked_unread @entry1
      expect(page).to have_text @entry2.title
      entry_should_be_marked_unread @entry2
    end

    it 'enables keyboard shortcuts', js: true do
      skip
      disable_kb_shortcuts @user
      read_feed @feed1, @user

      # Shortcuts should be disabled
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
      press_key Feedbunch::Application.config.kb_entries_down
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2

      enable_kb_shortcuts @user
      read_feed @feed1, @user

      # Shortcuts should be enabled
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
      press_key Feedbunch::Application.config.kb_entries_down
      entry_should_not_be_highlighted @entry1
      entry_should_be_highlighted @entry2

      feed_link_should_be_highlighted @feed1
      press_key Feedbunch::Application.config.kb_sidebar_link_up
      folder_link_should_be_highlighted 'none'
      feed_link_should_not_be_highlighted @feed1
    end
  end
end