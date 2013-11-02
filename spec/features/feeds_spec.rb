require 'spec_helper'

describe 'feeds' do

  it 'redirects unauthenticated visitors to login page' do
    visit read_path
    current_path.should eq new_user_session_path
  end

  context 'feed reading' do

    before :each do
      # Ensure no actual HTTP calls are made
      RestClient.stub get: true

      @user = FactoryGirl.create :user

      @folder1 = FactoryGirl.build :folder, user_id: @user.id
      @folder2 = FactoryGirl.create :folder
      @user.folders << @folder1

      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url
      @folder1.feeds << @feed1

      @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed1.entries << @entry1_1 << @entry1_2
      @feed2.entries << @entry2_1 << @entry2_2

      login_user_for_feature @user
      visit read_path
    end

    it 'shows feeds in the sidebar', js: true do
      within "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false do
        page.should have_text @feed1.title, visible: false
      end
      within "#sidebar #folder-none a[data-sidebar-feed][data-feed-id='#{@feed2.id}']", visible: false do
        page.should have_text @feed2.title, visible: false
      end
    end

    it 'shows an alert if it cannot load feeds', js: true do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      visit read_path
      should_show_alert 'problem-loading-feeds'
    end

    it 'hides entries menu button until a feed is selected', js: true do
      visit read_path
      page.should_not have_css '#entries-management', visible: true
    end

    it 'shows entries menu button when a feed is selected', js: true do
      read_feed @feed1, @user
      page.should have_css '#entries-management', visible: true
    end

    it 'shows entries for a feed in the All Subscriptions folder', js: true do
      read_feed @feed2, @user

      # Only entries for the clicked feed should appear
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
      page.should_not have_content @entry1_1.title
      page.should_not have_content @entry1_2.title
    end

    it 'shows entries for a feed inside a user folder', js: true do
      read_feed @feed1, @user

      # Only entries for the clicked feed should appear
      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows a link to read entries for all subscriptions', js: true do
      # Click on link to read all feeds
      find("#sidebar a[data-sidebar-feed][data-feed-id='all']").click

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
    end

    it 'shows a link to read all entries for all subscriptions inside a folder', js: true do
      # Add a second feed inside @folder1
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      @folder1.feeds << feed3
      entry3_1 = FactoryGirl.build :entry, feed_id: feed3.id
      entry3_2 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry3_1 << entry3_2

      within "#sidebar #folder-#{@folder1.id}" do
        # Open folder
        find("a#open-folder-#{@folder1.id}").click

        page.should have_css "li#folder-#{@folder1.id}-all-feeds"

        # Click on link to read all feeds
        find("li#folder-#{@folder1.id}-all-feeds > a").click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content entry3_1.title
      page.should have_content entry3_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows entries without a published date', js: true do
      entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id, published: nil
      @feed1.entries << entry1_3
      read_feed @feed1, @user
      page.should have_content entry1_3.title
    end

    it 'hides feeds after reading all their entries and clicking on a feed', js: true do
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_feed @feed2, @user
      # @feed1 should disappear
      page.should_not have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should disappear
      page.should_not have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'does not hide feeds after reading all their entries and clicking on the same feed', js: true do
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_feed @feed1, @user
      # @feed1 should not disappear
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should not disappear
      page.should have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'hides feeds after reading all their entries and clicking on a folder', js: true do
      # @feed1 is in @folder1, @feed2 is in folder2
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2
      folder2.feeds << @feed2

      visit read_path
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_folder folder2
      # @feed1 should disappear
      page.should_not have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should disappear
      page.should_not have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'does not hide feeds after reading all their entries and clicking on their folder', js: true do
      # @feed1 is in @folder1, @feed2 is in folder2
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_folder @folder1
      # @feed1 should not disappear
      page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should not disappear
      page.should have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'shows feeds without unread entries', js: true do
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      visit read_path

      # Feed without unread entries is not visible by default
      page.should_not have_css "[data-sidebar-feed][data-feed-id='#{feed3.id}']", visible: false

      # Click on "show read feeds" button
      find('#show-read-feeds').click
      page.should have_css "[data-sidebar-feed][data-feed-id='#{feed3.id}']", visible: false

      read_feed feed3, @user
      page.should have_text 'No entries'
    end

    it 'hides feeds without unread entries again', js: true do
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      visit read_path

      # Click on "show read feeds" button
      find('#show-read-feeds').click
      page.should have_css "[data-sidebar-feed][data-feed-id='#{feed3.id}']", visible: false

      # Click on "hide read feeds" button
      find('#hide-read-feeds').click
      page.should_not have_css "[data-sidebar-feed][data-feed-id='#{feed3.id}']", visible: false
    end

    it 'shows an alert if there is a problem loading a feed', js: true do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      # Try to read feed
      read_feed @feed1, @user

      should_show_alert 'problem-loading-entries'
    end
  end
end