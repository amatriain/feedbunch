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

    login_user_for_feature @user
    visit feeds_path
  end

  it 'hides unsubscribe button until a feed is selected', js: true do
    visit feeds_path
    page.should have_css 'a#unsubscribe-feed.hidden', visible: false
  end

  it 'shows unsubscribe button when a feed is selected', js: true do
    read_feed @feed1.id
    page.should_not have_css 'a#unsubscribe-feed.hidden', visible: false
    page.should_not have_css 'a#unsubscribe-feed.disabled', visible: false
    page.should have_css 'a#unsubscribe-feed'
  end

  it 'still shows buttons after unsubscribing from a feed', js: true do
    # Regression test for bug #152

    # Unsubscribe from @feed1
    unsubscribe_feed @feed1.id

    # Read @feed2. All buttons should be visible and enabled
    read_feed @feed2.id
    page.should have_css 'a#refresh-feed'
    page.should_not have_css 'a#refresh-feed.disabled'
    page.should have_css 'a#folder-management'
    page.should_not have_css 'a#folder-management.disabled'
    page.should have_css 'a#unsubscribe-feed'
    page.should_not have_css 'a#unsubscribe-feed.disabled'
  end

  it 'hides unsubscribe button when reading a whole folder', js: true do
    read_feed 'all'
    page.should have_css 'a#unsubscribe-feed.hidden', visible: false
    page.should have_css 'a#unsubscribe-feed.disabled', visible: false
  end

  it 'shows a confirmation popup', js: true do
    read_feed @feed1.id
    find('#unsubscribe-feed').click
    page.should have_css '#unsubscribe-feed-popup'
  end

  it 'unsubscribes from a feed', js: true do
    unsubscribe_feed @feed1.id

    # Only @feed2 should be present, @feed1 has been unsubscribed
    page.should_not have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed2.id}']", visible: false
  end

  it 'shows an alert if there is a problem unsubscribing from a feed', js: true do
    SubscriptionsManager.stub(:remove_subscription).and_raise StandardError.new

    unsubscribe_feed @feed1.id

    should_show_alert 'problem-unsubscribing'
  end

  it 'makes feed disappear from folders', js: true do
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed1

    visit feeds_path

    # Feed should be in the folder and in the "all subscriptions" folder
    page.should have_css "#sidebar li#folder-all li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should have_css "#sidebar li#folder-#{folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false

    unsubscribe_feed @feed1.id

    # Feed should disappear completely from both folders
    page.should_not have_css "#sidebar > li#folder-all li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should_not have_css "#sidebar > li#folder-#{folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'shows start page after unsubscribing', js: true do
    read_feed @feed1.id
    page.should have_css '#start-info.hidden', visible: false

    unsubscribe_feed @feed1.id

    page.should have_css '#start-info'
  end

  it 'still shows the feed for other subscribed users', js: true do
    user2 = FactoryGirl.create :user
    user2.subscribe @feed1.fetch_url

    # Unsubscribe @user from @feed1 and logout
    unsubscribe_feed @feed1.id
    find('#sign_out').click

    # user2 should still see the feed in his own list
    login_user_for_feature user2
    page.should have_css "li#folder-all ul#feeds-all a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'removes folders without feeds', js: true do
    # @user has folder, and @feed1 is in it.
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed1

    visit feeds_path
    page.should have_content folder.title

    unsubscribe_feed @feed1.id

    # Folder should be removed from the sidebar
    within '#sidebar #folders-list' do
      page.should_not have_content folder.title
    end
    page.should_not have_css "#folders-list li[data-folder-id='#{folder.id}']"

    read_feed @feed2.id
    # Folder should be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      page.should_not have_content folder.title
      page.should_not have_css "a[data-folder-id='#{folder.id}']"
    end
  end

  it 'does not remove folders with feeds', js: true do
    # @user has folder, and @feed1, @feed2 are in it.
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed1 << @feed2

    visit feeds_path
    page.should have_content folder.title

    unsubscribe_feed @feed1.id

    # Folder should not be removed from the sidebar
    within '#sidebar #folders-list' do
      page.should have_content folder.title
    end
    page.should have_css "#folders-list li[data-folder-id='#{folder.id}']"

    read_feed @feed2.id
    # Folder should not be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      page.should have_content folder.title
      page.should have_css "a[data-folder-id='#{folder.id}']"
    end
  end

end