require 'spec_helper'

describe 'start page' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @user.subscribe @feed1.fetch_url
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1

    login_user_for_feature @user
    visit read_path
  end

  it 'shows start page by default', js: true do
    page.should have_css '#start-info'
    page.should_not have_css '#feed-entries', visible: true
  end

  it 'hides feed title and entries by default', js: true do
    page.should_not have_css '#feed-title', visible: true
    page.should_not have_css '#feed-entries', visible: true
  end

  it 'hides Read All button by default', js: true do
    page.should_not have_css '#read-all-button', visible: true
  end

  it 'hides folder management button by default', js: true do
    page.should_not have_css '#folder-management', visible: true
  end

  it 'hides start page when reading a feed', js: true do
    page.should have_css '#start-info'
    page.should_not have_css '#feed-entries', visible: true

    read_feed @feed1, @user

    page.should_not have_css '#start-info', visible: true
    page.should have_css '#feed-entries'
  end

  context 'click on Start link' do

    before :each do
      # click on a feed, then click on the Start link
      read_feed @feed1, @user
      find('#start-page').click
    end

    it 'shows start page', js: true do
      page.should have_css '#start-info'
      page.should_not have_css '#feed-entries', visible: true
    end

    it 'hides feed title and entries', js: true do
      page.should_not have_css '#feed-title', visible: true
      page.should_not have_css '#feed-entries', visible: true
    end

    it 'hides Read All button', js: true do
      page.should_not have_css '#read-all-button', visible: true
    end

  end

  context 'stats' do

    before :each do
      @feed2 = FactoryGirl.create :feed
      @user.subscribe @feed2.fetch_url
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry2 << @entry3

      visit read_path
    end

    it 'shows number of subscribed feeds', js: true do
      page.should have_content '2 feeds'
    end

    it 'shows number of unread entries', js: true do
      page.should have_content '3 unread entries'
    end
  end

end