require 'rails_helper'

describe 'unsubscribe from feed', type: :feature do

  before :each do
    @user = FactoryBot.create :user
    @feed1 = FactoryBot.create :feed
    @feed2 = FactoryBot.create :feed
    @entry1 = FactoryBot.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @entry2 = FactoryBot.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2
    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @folder = FactoryBot.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed1

    # Process unsubscriptions synchronously, instead of asynchronously with sidekiq
    allow_any_instance_of(User).to receive :enqueue_unsubscribe_job do |user, feed|
      user.unsubscribe feed
    end

    login_user_for_feature @user
    visit read_path
  end

  it 'hides unsubscribe button until a feed is selected', js: true do
    visit read_path
    open_feeds_menu
    expect(page).to have_no_css '#unsubscribe-feed', visible: true
  end

  it 'shows unsubscribe button when a feed is selected', js: true do
    read_feed @feed1, @user
    open_feeds_menu
    expect(page).to have_css '#unsubscribe-feed', visible: true
  end

  it 'still shows buttons after unsubscribing from a feed', js: true do
    # Regression test for bug #152

    # Unsubscribe from @feed1
    unsubscribe_feed @feed1, @user

    # Read @feed2. All buttons should be visible and enabled
    read_feed @feed2, @user
    expect(page).to have_css '#show-read', visible: true
    expect(page).to have_css '#feeds-management', visible: true
    expect(page).to have_css '#read-all-button', visible: true
    expect(page).to have_css '#folder-management', visible: true
  end

  it 'hides unsubscribe button when reading all feeds', js: true do
    read_folder 'all'
    open_feeds_menu
    expect(page).to have_no_css '#unsubscribe-feed', visible: true
  end

  it 'hides unsubscribe button when reading a whole folder', js: true do
    # @feed1, feed3 are in @folder
    feed3 = FactoryBot.create :feed
    entry3 = FactoryBot.build :entry, feed_id: feed3.id
    feed3.entries << entry3
    @user.subscribe feed3.fetch_url
    @folder.feeds << feed3
    visit read_path

    read_folder @folder
    open_feeds_menu
    expect(page).to have_no_css '#unsubscribe-feed', visible: true
  end

  it 'shows a confirmation popup', js: true do
    read_feed @feed1, @user
    open_feeds_menu
    find('#unsubscribe-feed').click
    expect(page).to have_css '#unsubscribe-feed-popup'
  end

  it 'unsubscribes from a feed', js: true do
    unsubscribe_feed @feed1, @user

    # Only @feed2 should be present, @feed1 has been unsubscribed
    expect(page).to have_no_css "#sidebar li > a[data-feed-id='#{@feed1.id}']", visible: false
    expect(page).to have_css "#sidebar li > a[data-feed-id='#{@feed2.id}']", visible: false
  end

  it 'shows an alert if there is a problem unsubscribing from a feed', js: true do
    allow_any_instance_of(User).to receive(:enqueue_unsubscribe_job).and_raise StandardError.new

    unsubscribe_feed @feed1, @user

    should_show_alert 'problem-unsubscribing'
  end

  it 'makes feed disappear from folder', js: true do
    # Feed should be in the folder
    expect(page).to have_css "#sidebar #folder-#{@folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false

    unsubscribe_feed @feed1, @user

    # Feed should disappear completely from the folder
    expect(page).to have_no_css "#sidebar > li#folder-#{@folder.id} li > a[data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'shows start page after unsubscribing', js: true do
    read_feed @feed1, @user
    expect(page).to have_no_css '#start-info', visible: true

    unsubscribe_feed @feed1, @user

    expect(page).to have_css '#start-info', visible: true
  end

  it 'still shows the feed for other subscribed users', js: true do
    user2 = FactoryBot.create :user
    user2.subscribe @feed1.fetch_url

    # Unsubscribe @user from @feed1 and logout
    unsubscribe_feed @feed1, @user
    logout_user_for_feature

    # user2 should still see the feed in his own list
    login_user_for_feature user2
    expect(page).to have_css "#folder-none a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
  end

  it 'removes folders without feeds', js: true do
    unsubscribe_feed @feed1, @user

    # Folder should be removed from the sidebar
    within '#sidebar #folders-list' do
      expect(page).to have_no_content @folder.title
    end
    expect(page).to have_no_css "#folders-list li[data-folder-id='#{@folder.id}']"

    read_feed @feed2, @user
    # Folder should be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      expect(page).to have_no_content @folder.title
      expect(page).to have_no_css "a[data-folder-id='#{@folder.id}']"
    end
  end

  it 'does not remove folders with other feeds without unread entries', js: true do
    feed3 = FactoryBot.create :feed
    @user.subscribe feed3.fetch_url
    @folder.feeds << feed3
    visit read_path

    unsubscribe_feed @feed1, @user

    # Folder should be removed from the sidebar (it has no unread entries)
    within '#sidebar #folders-list' do
      expect(page).to have_no_content @folder.title
    end
    expect(page).to have_no_css "#folders-list li[data-folder-id='#{@folder.id}']"

    read_feed @feed2, @user
    # Folder should not be removed from the dropdown (all folders appear in the dropdown, regardless
    # of whether they have unread entries or not)
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      expect(page).to have_content @folder.title
      expect(page).to have_css "a[data-folder-id='#{@folder.id}']"
    end
  end

  it 'does not remove folders with feeds', js: true do
    # @user has folder, and @feed1, @feed2 are in it.
    @folder.feeds << @feed2

    visit read_path
    expect(page).to have_content @folder.title

    unsubscribe_feed @feed1, @user

    # Folder should not be removed from the sidebar
    within '#sidebar #folders-list' do
      expect(page).to have_content @folder.title
    end
    expect(page).to have_css "#folders-list [data-folder-id='#{@folder.id}']"

    read_feed @feed2, @user
    # Folder should not be removed from the dropdown
    find('#folder-management').click
    within '#folder-management-dropdown ul.dropdown-menu' do
      expect(page).to have_content @folder.title
      expect(page).to have_css "a[data-folder-id='#{@folder.id}']"
    end
  end

  context 'job states' do

    before :each do
      # Immediately unsubscribe from feed
      allow_any_instance_of(User).to receive :enqueue_unsubscribe_job do |user, feed|
        user.unsubscribe feed
      end
    end

    it 'removes refresh job state alert for the unsubscribed feed', js: true do
      job_state = FactoryBot.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed1.id
      @user.refresh_feed_job_states << job_state
      go_to_start_page
      within '#refresh-state-alerts' do
        expect(page).to have_text 'Currently refreshing feed'
        expect(page).to have_content @feed1.title
      end

      unsubscribe_feed @feed1, @user

      expect(page).to have_css '#subscription-stats'
      expect(page).to have_no_text 'Currently refreshing feed'
      expect(page).to have_no_content @feed1.title
    end

    it 'removes subscribe job state alert for the unsubscribed feed', js: true do
      job_state = FactoryBot.build :subscribe_job_state, user_id: @user.id, feed_id: @feed1.id,
                                    fetch_url: @feed1.fetch_url, state: SubscribeJobState::SUCCESS
      @user.subscribe_job_states << job_state
      go_to_start_page
      within '#subscribe-state-alerts' do
        expect(page).to have_text 'Successfully added subscription to feed'
        expect(page).to have_content @feed1.title
      end

      # Immediately unsubscribe from feed
      allow_any_instance_of(User).to receive :enqueue_unsubscribe_job do |user, feed|
        user.unsubscribe feed
      end

      unsubscribe_feed @feed1, @user

      expect(page).to have_css '#subscription-stats'
      expect(page).to have_no_text 'Successfully added subscription to feed'
      expect(page).to have_no_content @feed1.title
    end
  end
end