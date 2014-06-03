require 'spec_helper'

describe 'start page', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @user.subscribe @feed1.fetch_url

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
      go_to_start_page
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
      # @user is subscribed to @feed1, @feed2 and @feed3
      # @feed1 has one unread entry, @feed2 has two unread entries, and @feed3 has one read entry
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed
      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry4 = FactoryGirl.build :entry, feed_id: @feed3.id
      @feed2.entries << @entry2 << @entry3
      @feed3.entries << @entry4
      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url
      @user.change_entries_state @entry4, 'read'

      visit read_path
    end

    it 'shows number of subscribed feeds', js: true do
      page.should have_content 'Subscribed to 3 feeds'
    end

    it 'updates number of subscribed feeds when subscribing to a feed', js: true do
      feed4 = FactoryGirl.create :feed
      job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: feed4.fetch_url
      User.any_instance.stub :enqueue_subscribe_job do |user, url|
        if user.id == @user.id
          user.subscribe feed4.fetch_url
          user.subscribe_job_states << job_state
        end
      end

      User.any_instance.stub :find_subscribe_job_state do |user|
        if user.id == @user.id
          job_state.update state: SubscribeJobState::SUCCESS
          job_state
        end
      end

      subscribe_feed feed4.fetch_url
      go_to_start_page
      page.should have_content 'Subscribed to 4 feeds'
    end

    it 'updates number of subscribed feeds when unsubscribing from a feed', js: true do
      feed4 = FactoryGirl.create :feed
      unsubscribe_feed @feed1, @user
      go_to_start_page
      page.should have_content 'Subscribed to 2 feeds'
    end

    it 'shows number of unread entries', js: true do
      page.should have_content 'with 3 unread entries'
    end

    it 'updates number of unread entries when marking entries as read', js: true do
      read_feed @feed1, @user
      read_entry @entry1
      go_to_start_page
      page.should have_content 'with 2 unread entries'
    end

    it 'updates number of unread entries when marking entries as unread', js: true do
      show_read
      read_feed @feed3, @user
      unread_entry @entry4
      go_to_start_page
      page.should have_content 'with 4 unread entries'
    end
  end

end