require 'spec_helper'

describe 'feed entries' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
    @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry1 << @entry2
    @user.feeds << @feed

    login_user_for_feature @user
    visit feeds_path
    read_feed @feed.id
  end

  it 'opens an entry', js: true do
    within 'ul#feed-entries' do
      # Entry summary should not be visible
      page.should_not have_content @entry1.summary

      # Open entry
      find("li#entry-#{@entry1.id} > a").click

      # Summary should appear
      page.should have_content @entry1.summary
    end
  end

  it 'closes other entries when opening an entry', js: true do
    within 'ul#feed-entries' do
      # Open first entry, give it some time for open animation
      find("li#entry-#{@entry1.id} > a").click
      sleep 1

      # Only summary of first entry should be visible
      page.should have_content @entry1.summary
      page.should_not have_content @entry2.summary

      # Open second entry, give it some time for open animation
      find("li#entry-#{@entry2.id} > a").click
      sleep 1

      # Only summary of second entry should be visible
      page.should_not have_content @entry1.summary
      page.should have_content @entry2.summary
    end
  end

  it 'by default only shows unread entries in a feed', js: true do
    entry_state = EntryState.where(entry_id: @entry1.id, user_id: @user.id ).first
    entry_state.read = true
    entry_state.save!

    read_feed @feed.id

    page.should have_content @entry2.title
    page.should_not have_content @entry1.title
  end

  it 'by default only shows unread entries in a folder'

  it 'marks as read an entry when opening it'

  it 'marks all entries as read'

  it 'marks an entry as unread'

end