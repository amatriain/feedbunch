require 'spec_helper'

describe 'unread entries count' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder1

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1 << @feed2
    @folder1.feeds << @feed1

    @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed1.entries << @entry1_1 << @entry1_2 << @entry1_3
    @feed2.entries << @entry2_1

    login_user_for_feature @user
    visit feeds_path
  end

  it 'shows total number of unread entries', js: true do
    within '#sidebar #folders-list #folder-all #feeds-all #folder-all-all-feeds' do
      page.should have_content 'Read all subscriptions (4)'
    end
  end

  it 'shows number of unread entries in a folder', js: true do
    within "#sidebar #folders-list #folder-#{@folder1.id} #feeds-#{@folder1.id} #folder-#{@folder1.id}-all-feeds" do
      page.should have_content 'Read all subscriptions (3)'
    end
  end

  it 'shows number of unread entries in a single feed', js: true do
    within '#sidebar #folders-list #folder-all #feeds-all' do
      page.should have_content "#{@feed1.title} (3)"
      page.should have_content "#{@feed2.title} (1)"
    end
  end

  it 'updates number of unread entries when clicking on a folder'

  it 'updates number of unread entries when clicking on a feed'

  it 'shows number of unread entries in a newly created folder'

  it 'shows number of unread entries in a newly subscribed feed'

  it 'updates number of unread entries when moving a feed into a folder'

  it 'updates number of unread entries when removing a feed from a folder'

  it 'updates number of unread entries when unsubscribing from a feed'
end