require 'rails_helper'

describe 'feeds', type: :feature do

  before :each do
    # Ensure no actual HTTP calls are made
    allow(RestClient).to receive(:get).and_return true

    @user = FactoryGirl.create :user
  end

  it 'redirects unauthenticated visitors to login page' do
    visit read_path
    expect(current_path).to eq new_user_session_path
  end

  it 'shows an alert if it cannot load feeds', js: true do
    skip
    allow_any_instance_of(User).to receive(:subscribed_feeds).and_raise StandardError.new
    login_user_for_feature @user
    should_show_alert 'problem-loading-feeds'
  end

  context 'feed reading' do

    before :each do
      @folder1 = FactoryGirl.build :folder, user_id: @user.id
      @folder2 = FactoryGirl.create :folder
      @user.folders << @folder1

      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed

      @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry3_1 = FactoryGirl.build :entry, feed_id: @feed3.id
      @entry3_2 = FactoryGirl.build :entry, feed_id: @feed3.id
      @feed1.entries << @entry1_1 << @entry1_2
      @feed2.entries << @entry2_1 << @entry2_2
      @feed3.entries << @entry3_1 << @entry3_2

      # @user is subscribed to @feed1, @feed2 and @feed3
      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url

      # @feed1 and @feed2 are in @folder1, @feed3 isn't in a folder
      @folder1.feeds << @feed1 << @feed2

      login_user_for_feature @user
    end

    it 'shows feeds in the sidebar', js: true do
      open_folder @folder1

      within "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']" do
        expect(page).to have_text @feed1.title
      end
      within "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}']" do
        expect(page).to have_text @feed2.title
      end
      within "#sidebar #folder-none a[data-sidebar-feed][data-feed-id='#{@feed3.id}']" do
        expect(page).to have_text @feed3.title
      end
    end

    it 'hides Read All button until a feed is selected', js: true do
      visit read_path
      expect(page).to have_no_css '#read-all-button', visible: true
    end

    it 'shows Read All button when a feed is selected', js: true do
      read_feed @feed1, @user
      expect(page).to have_css '#read-all-button', visible: true
    end

    it 'shows feed title when a feed is selected', js: true do
      read_feed @feed1, @user
      expect(page).to have_css '#feed-title', visible: true
      within '#feed-title' do
        expect(page).to have_text @feed1.title
      end
    end

    it 'shows entries for a feed not in a folder', js: true do
      read_feed @feed3, @user

      # Only entries for the clicked feed should appear
      expect(page).to have_content @entry3_1.title
      expect(page).to have_content @entry3_2.title
      expect(page).to have_no_content @entry1_1.title
      expect(page).to have_no_content @entry1_2.title
      expect(page).to have_no_content @entry2_1.title
      expect(page).to have_no_content @entry2_2.title
    end

    it 'shows entries for a feed in a user folder', js: true do
      read_feed @feed1, @user

      # Only entries for the clicked feed should appear
      expect(page).to have_content @entry1_1.title
      expect(page).to have_content @entry1_2.title
      expect(page).to have_no_content @entry2_1.title
      expect(page).to have_no_content @entry2_2.title
      expect(page).to have_no_content @entry3_1.title
      expect(page).to have_no_content @entry3_2.title
    end

    it 'shows entries without a published date', js: true do
      entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id, published: nil
      @feed1.entries << entry1_3
      read_feed @feed1, @user
      expect(page).to have_content entry1_3.title
    end

    it 'hides feeds after reading all their entries and clicking on a feed', js: true do
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_feed @feed2, @user
      # @feed1 should disappear
      expect(page).to have_no_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should not disappear
      expect(page).to have_css "#sidebar #folder-#{@folder1.id}", visible: false

      mark_all_as_read

      # @feed2 should still be present
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}']", visible: false

      read_feed @feed3, @user
      # @feed1 and @feed2 should disappear
      expect(page).to have_no_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      expect(page).to have_no_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}']", visible: false
      # @folder1 should  disappear
      expect(page).to have_no_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'does not hide feeds after reading all their entries and clicking on the same feed', js: true do
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_feed @feed1, @user
      # @feed1 should not disappear
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should not disappear
      expect(page).to have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'hides feeds after reading all their entries and clicking on another folder', js: true do
      # @feed1 and @feed2 are in @folder1, @feed3 is in folder2
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2
      folder2.feeds << @feed3

      visit read_path
      read_feed @feed3, @user
      mark_all_as_read

      # @feed3 should still be present
      expect(page).to have_css "#sidebar #folder-#{folder2.id} a[data-sidebar-feed][data-feed-id='#{@feed3.id}']", visible: false

      read_folder @folder1
      # @feed3 should disappear
      expect(page).to have_no_css "#sidebar #folder-#{folder2.id} a[data-sidebar-feed][data-feed-id='#{@feed3.id}']", visible: false
      # folder2 should disappear
      expect(page).to have_no_css "#sidebar #folder-#{folder2.id}", visible: false
    end

    it 'does not hide feeds after reading all their entries and clicking on their folder', js: true do
      # @feed1 and @feed2 are in @folder1
      read_feed @feed1, @user
      mark_all_as_read

      # @feed1 should still be present
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

      read_folder @folder1
      # @feed1 should not disappear
      expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
      # @folder1 should not disappear
      expect(page).to have_css "#sidebar #folder-#{@folder1.id}", visible: false
    end

    it 'shows feeds without unread entries', js: true do
      feed4 = FactoryGirl.create :feed
      @user.subscribe feed4.fetch_url
      visit read_path

      # Feed without unread entries is not visible by default
      expect(page).to have_no_css "[data-sidebar-feed][data-feed-id='#{feed4.id}']", visible: false

      # Click on "show read" button
      show_read
      expect(page).to have_css "[data-sidebar-feed][data-feed-id='#{feed4.id}']", visible: false

      read_feed feed4, @user
      expect(page).to have_text 'No entries'
    end

    it 'hides feeds without unread entries again', js: true do
      feed4 = FactoryGirl.create :feed
      @user.subscribe feed4.fetch_url
      visit read_path

      # Click on "show read" button
      show_read
      expect(page).to have_css "[data-sidebar-feed][data-feed-id='#{feed4.id}']", visible: false

      # Click on "hide read feeds" button
      hide_read
      expect(page).to have_no_css "[data-sidebar-feed][data-feed-id='#{feed4.id}']", visible: false
    end

    it 'shows an alert if there is a problem loading a feed', js: true do
      allow_any_instance_of(User).to receive(:feed_entries).and_raise StandardError.new
      # Try to read feed
      read_feed @feed1, @user

      should_show_alert 'problem-loading-entries'
    end

    context 'read all subscriptions' do

      before :each do
        # @feed1 and @feed2 are in @folder1, @feed3 is in @folder2
        @folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << @folder2
        @folder2.feeds << @feed3

        visit read_path
      end

      it 'shows a link to read entries in all subscriptions', js: true do
        expect(page).to have_css "#sidebar a[data-sidebar-feed][data-feed-id='all']"
        # Wait for the "all subscriptions" link to become enabled
        expect(page).to have_no_css "#sidebar #feeds-all.disabled a[data-sidebar-feed][data-feed-id='all']"

        # Click on link to read all feeds
        find("#sidebar #folder-none a[data-sidebar-feed][data-feed-id='all']").click

        expect(page).to have_content @entry1_1.title
        expect(page).to have_content @entry1_2.title
        expect(page).to have_content @entry2_1.title
        expect(page).to have_content @entry2_2.title
        expect(page).to have_content @entry3_1.title
        expect(page).to have_content @entry3_2.title
      end

      # Regression test
      it 'shows a link to read all entries even if the user has no folders', js: true do
        logout_user

        user = FactoryGirl.create :user
        feed1 = FactoryGirl.create :feed
        feed2 = FactoryGirl.create :feed

        entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
        entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
        feed1.entries << entry1
        feed2.entries << entry2

        user.subscribe feed1.fetch_url
        user.subscribe feed2.fetch_url

        login_user_for_feature user

        expect(page).to have_css "#sidebar a[data-sidebar-feed][data-feed-id='all']"
        # Wait for the "all subscriptions" link to become enabled
        expect(page).to have_no_css "#sidebar #feeds-all.disabled a[data-sidebar-feed][data-feed-id='all']"

        # Click on link to read all feeds
        find("#sidebar #folder-none a[data-sidebar-feed][data-feed-id='all']").click

        expect(page).to have_content entry1.title
        expect(page).to have_content entry2.title
      end

      it 'shows a link to read all entries for all subscriptions in a folder if it has several feeds', js: true do
        within "#sidebar #folder-#{@folder1.id}" do
          # Open folder
          find("a#open-folder-#{@folder1.id}").click

          expect(page).to have_css "li#folder-#{@folder1.id}-all-feeds"

          # Click on link to read all feeds
          find("li#folder-#{@folder1.id}-all-feeds > a").click
        end

        expect(page).to have_content @entry1_1.title
        expect(page).to have_content @entry1_2.title
        expect(page).to have_content @entry2_1.title
        expect(page).to have_content @entry2_2.title
        expect(page).to have_no_content @entry3_1.title
        expect(page).to have_no_content @entry3_2.title
      end

      it 'does not show link to read all subscriptions in a folder if it has only one feed', js: true do
        within "#sidebar #folder-#{@folder2.id}" do
          # Open folder
          find("a#open-folder-#{@folder2.id}").click
          expect(page).to have_no_css "li#folder-#{@folder2.id}-all-feeds"
        end
      end

      it 'does not show link to read all subscriptions in a folder if it has several feeds but only one with unread entries', js: true do
        # Add a second feed inside @folder2
        feed4 = FactoryGirl.create :feed
        @user.subscribe feed4.fetch_url
        @folder2.feeds << feed4
        visit read_path

        within "#sidebar #folder-#{@folder2.id}" do
          # Open folder
          find("a#open-folder-#{@folder2.id}").click
          expect(page).to have_no_css "li#folder-#{@folder2.id}-all-feeds"
        end
      end
    end
  end
end