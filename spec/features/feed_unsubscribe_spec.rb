require 'spec_helper'

describe 'unsubscribe from feed' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed1

    login_user_for_feature @user
    visit read_path
  end

  it 'hides unsubscribe button until a feed is selected', js: true do
    visit read_path
    open_feeds_menu
    page.should_not have_css '#unsubscribe-feed', visible: true
  end

  it 'shows unsubscribe button when a feed is selected', js: true do
    read_feed @feed1, @user
    open_feeds_menu
    page.should have_css '#unsubscribe-feed', visible: true
  end

  it 'still shows buttons after unsubscribing from a feed', js: true do
    # Regression test for bug #152

    # Unsubscribe from @feed1
    unsubscribe_feed @feed1, @user

    # Read @feed2. All buttons should be visible and enabled
    read_feed @feed2, @user
    page.should have_css '#show-read', visible: true
    page.should have_css '#feeds-management', visible: true
    page.should have_css '#read-all-button', visible: true
    page.should have_css '#folder-management', visible: true
  end

  it 'hides unsubscribe button when reading all feeds', js: true do
    read_folder 'all'
    open_feeds_menu
    page.should_not have_css '#unsubscribe-feed', visible: true
  end

  it 'hides unsubscribe button when reading a whole folder', js: true do
    read_folder @folder
    open_feeds_menu
    page.should_not have_css '#unsubscribe-feed', visible: true
  end

  it 'shows a confirmation popup', js: true do
    read_feed @feed1, @user
    open_feeds_menu
    find('#unsubscribe-feed').click
    page.should have_css '#unsubscribe-feed-popup'
  end

  it 'unsubscribes from a feed', js: true do
    unsubscribe_feed @feed1, @user

    # Only @feed2 should be present, @feed1 has been unsubscribed
    page.should_not have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed2.id}']", visible: false
  end

  it 'shows an alert if there is a problem unsubscribing from a feed', js: true do
    SubscriptionsManager.stub(:remove_subscription).and_raise StandardError.new

    unsubscribe_feed @feed1, @user

    should_show_alert 'problem-unsubscribing'
  end

  it 'makes feed disappear from folder', js: true do
    # Feed should be in the folder
    page.should have_css "#sidebar #folder-#{@folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

    unsubscribe_feed @feed1, @user

    # Feed should disappear completely from the folder
    page.should_not have_css "#sidebar > li#folder-#{@folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'shows start page after unsubscribing', js: true do
    read_feed @feed1, @user
    page.should_not have_css '#start-info', visible: true

    unsubscribe_feed @feed1, @user

    page.should have_css '#start-info', visible: true
  end

  it 'still shows the feed for other subscribed users', js: true do
    user2 = FactoryGirl.create :user
    user2.subscribe @feed1.fetch_url

    # Unsubscribe @user from @feed1 and logout
    unsubscribe_feed @feed1, @user
    logout_user

    # user2 should still see the feed in his own list
    login_user_for_feature user2
    page.should have_css "#folder-none a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'removes folders without feeds', js: true do
    unsubscribe_feed @feed1, @user

    # Folder should be removed from the sidebar
    within '#sidebar #folders-list' do
      page.should_not have_content @folder.title
    end
    page.should_not have_css "#folders-list li[data-folder-id='#{@folder.id}']"

    read_feed @feed2, @user
    # Folder should be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      page.should_not have_content @folder.title
      page.should_not have_css "a[data-folder-id='#{@folder.id}']"
    end
  end

  it 'does not remove folders with feeds', js: true do
    # @user has folder, and @feed1, @feed2 are in it.
    @folder.feeds << @feed2

    visit read_path
    page.should have_content @folder.title

    unsubscribe_feed @feed1, @user

    # Folder should not be removed from the sidebar
    within '#sidebar #folders-list' do
      page.should have_content @folder.title
    end
    page.should have_css "#folders-list [data-folder-id='#{@folder.id}']"

    read_feed @feed2, @user
    # Folder should not be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      page.should have_content @folder.title
      page.should have_css "a[data-folder-id='#{@folder.id}']"
    end
  end

end