require 'spec_helper'

describe 'feeds' do
  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true
  end

  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
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

      @feed1 = FactoryGirl.build :feed
      @feed2 = FactoryGirl.build :feed
      @user.feeds << @feed1 << @feed2
      @folder1.feeds << @feed1

      @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed1.entries << @entry1_1 << @entry1_2
      @feed2.entries << @entry2_1 << @entry2_2

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows entries for a feed in the All Subscriptions folder', js: true do
      within '#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        # click on feed
        find("#sidebar li > a[data-feed-id='#{@feed2.id}']").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
      page.should_not have_content @entry1_1.title
      page.should_not have_content @entry1_2.title
    end

    it 'shows entries for a feed inside a user folder', js: true do
      within "#sidebar li#folder-#{@folder1.id}" do
        # Open folder @folder1
        find("a[data-target='#feeds-#{@folder1.id}']").click

        # Click on feed
        find("#sidebar li > a[data-feed-id='#{@feed1.id}']").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows a link to read entries for all subscriptions inside the All Subscriptions folder', js: true do
      within '#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        page.should have_css 'li#folder-all-all-feeds'

        # Click on link to read all feeds
        find('li#folder-all-all-feeds > a').click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
    end

    it 'shows a link to read all entries for all subscriptions inside a folder', js: true do
      # Add a second feed inside @folder1
      feed3 = FactoryGirl.create :feed
      @user.feeds << feed3
      @folder1.feeds << feed3
      entry3_1 = FactoryGirl.build :entry, feed_id: feed3.id
      entry3_2 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry3_1 << entry3_2

      within "#sidebar li#folder-#{@folder1.id}" do
        # Open folder
        find("a[data-target='#feeds-#{@folder1.id}']").click

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

    it 'shows an alert if the feed clicked has no entries', js: true do
      feed3 = FactoryGirl.create :feed
      @user.feeds << feed3
      visit feeds_path
      read_feed feed3.id

      # A "no entries" alert should be shown
      page.should have_css 'div#no-entries'
      page.should_not have_css 'div#no-entries.hidden', visible: false

      # It should close automatically after 5 seconds
      sleep 5
      page.should have_css 'div#no-entries.hidden', visible: false
    end

    it 'shows an alert if there is a problem loading a feed', js: true do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      # Try to read feed
      read_feed @feed1.id

      # A "problem loading feed" alert should be shown
      page.should have_css 'div#problem-loading'
      page.should_not have_css 'div#problem-loading.hidden', visible: false

      # It should close automatically after 5 seconds
      sleep 5
      page.should have_css 'div#problem-loading.hidden', visible: false
    end
  end
end