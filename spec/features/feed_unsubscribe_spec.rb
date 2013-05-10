require 'spec_helper'

describe 'unsubscribe from feed' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1 << @feed2
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1

    login_user_for_feature @user
    visit feeds_path
    read_feed @feed1.id
  end

  it 'hides unsubscribe button until a feed is selected', js: true do
    visit feeds_path
    page.should have_css 'a#unsubscribe-feed.hidden', visible: false
  end

  it 'shows unsubscribe button when a feed is selected', js: true do
    page.should_not have_css 'a#unsubscribe-feed.hidden', visible: false
    page.should_not have_css 'a#unsubscribe-feed.disabled', visible: false
    page.should have_css 'a#unsubscribe-feed'
  end

  it 'hides unsubscribe button when reading a whole folder', js: true do
    read_feed 'all'
    sleep 1
    page.should have_css 'a#unsubscribe-feed.hidden', visible: false
    page.should have_css 'a#unsubscribe-feed.disabled', visible: false
    page.should_not have_css 'a#unsubscribe-feed'
  end

  it 'shows a confirmation popup', js: true do
    find('#unsubscribe-feed').click
    page.should have_css '#unsubscribe-feed-popup'
  end

  it 'unsubscribes from a feed', js: true do
    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click

    # Only @feed2 should be present, @feed1 has been unsubscribed
    page.should_not have_css "ul#sidebar li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should have_css "ul#sidebar li > a[data-feed-id='#{@feed2.id}']", visible: false
  end

  it 'shows an alert if there is a problem unsubscribing from a feed', js: true do
    User.any_instance.stub(:feeds).and_raise StandardError.new

    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click

    # A "problem refreshing feed" alert should be shown
    page.should have_css 'div#problem-unsubscribing'
    page.should_not have_css 'div#problem-unsubscribing.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#problem-unsubscribing.hidden', visible: false
  end

  it 'deletes a feed if there are no users subscribed to it', js: true do
    Feed.exists?(@feed1.id).should be_true

    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click
    sleep 1

    Feed.exists?(@feed1.id).should be_false
  end

  it 'makes feed disappear from folders', js: true do
    folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << folder
    folder.feeds << @feed1
    visit feeds_path
    read_feed @feed1.id

    # Feed should be in the folder and in the "all subscriptions" folder
    page.should have_css "ul#sidebar > li#folder-all li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should have_css "ul#sidebar > li#folder-#{folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false

    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click
    sleep 1

    # Feed should disappear completely from both folders
    page.should_not have_css "ul#sidebar > li#folder-all li > a[data-feed-id='#{@feed1.id}']", visible: false
    page.should_not have_css "ul#sidebar > li#folder-#{folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'shows start page after unsubscribing', js: true do
    page.should have_css '#start-info.hidden', visible: false

    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click
    sleep 1

    page.should have_css '#start-info'
  end

  it 'still shows the feed for other subscribed users', js: true do
    user2 = FactoryGirl.create :user
    user2.feeds << @feed1

    # Unsubscribe @user from @feed1 and logout
    find('#unsubscribe-feed').click
    sleep 1
    find('#unsubscribe-submit').click
    sleep 1
    find('#sign_out').click

    # user2 should still see the feed in his own list
    login_user_for_feature user2
    page.should have_css "li#folder-all ul#feeds-all a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'still shows folders with feeds'

  it 'makes disappear folders without feeds'

end