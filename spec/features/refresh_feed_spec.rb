require 'spec_helper'

describe 'refresh feeds' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @user.feeds << @feed1
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1

    login_user_for_feature @user
    visit feeds_path
    read_feed @feed1.id
  end

  it 'hides refresh button until a feed is selected', js: true do
    visit feeds_path
    page.should have_css 'a#refresh-feed.hidden', visible: false
  end

  it 'shows refresh button when a feed is selected', js: true do
    page.should_not have_css 'a#refresh-feed.hidden', visible: false
    page.should have_css 'a#refresh-feed'
  end

  it 'refreshes a single feed', js: true do
    # Page should have current entries for the feed
    page.should have_content @entry1.title

    # Refresh feed
    entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
    FeedClient.should_receive(:fetch).with @feed1.id
    @feed1.entries << entry2
    find('a#refresh-feed').click

    # Page should have the new entries for the feed
    page.should have_content @entry1.title
    page.should have_content entry2.title
  end

  it 'refreshes all subscribed feeds', js: true do
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed2
    entry2 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry2

    visit feeds_path
    # Click on "Read all subscriptions" within the "All subscriptions" folder
    within '#sidebar li#folder-all' do
      # Open "All subscriptions" folder
      find("a[data-target='#feeds-all']").click
      # Click on "Read all subscriptions"
      find('li#folder-all-all-feeds > a').click
    end

    # Page should have current entries for the two feeds
    page.should have_content @entry1.title
    page.should have_content entry2.title

    # Refresh feed
    entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << entry3
    entry4 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry4
    FeedClient.should_receive(:fetch).with @feed1.id
    FeedClient.should_receive(:fetch).with feed2.id
    find('a#refresh-feed').click

    # Page should have the new entries for the feed
    page.should have_content @entry1.title
    page.should have_content entry2.title
    page.should have_content entry3.title
    page.should have_content entry4.title
  end

  it 'refreshes all subscribed feeds inside a folder', js: true do
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed2
    folder.feeds << @feed1 << feed2
    entry2 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry2

    visit feeds_path
    # Click on "Read all subscriptions" within the folder
    within "#sidebar li#folder-#{folder.id}" do
      # Open folder
      find("a[data-target='#feeds-#{folder.id}']").click
      # Click on "Read all subscriptions"
      find("li#folder-#{folder.id}-all-feeds > a").click
    end

    # Page should have current entries for the two feeds
    page.should have_content @entry1.title
    page.should have_content entry2.title

    # Refresh feed
    entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << entry3
    entry4 = FactoryGirl.build :entry, feed_id: feed2.id
    feed2.entries << entry4
    FeedClient.should_receive(:fetch).with @feed1.id
    FeedClient.should_receive(:fetch).with feed2.id
    find('a#refresh-feed').click

    # Page should have the new entries for the feed
    page.should have_content @entry1.title
    page.should have_content entry2.title
    page.should have_content entry3.title
    page.should have_content entry4.title
  end

  it 'shows an alert if there is a problem refreshing a feed', js: true do
    FeedClient.stub(:fetch).and_raise ActiveRecord::RecordNotFound.new
    # Refresh feed
    find('a#refresh-feed').click

    # A "problem refreshing feed" alert should be shown
    page.should have_css 'div#problem-refreshing'
    page.should_not have_css 'div#problem-refreshing.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#problem-refreshing.hidden', visible: false
  end

end