require 'spec_helper'

describe 'refresh feeds' do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    @user.subscribe @feed.fetch_url

    @job_state = FactoryGirl.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed.id
    User.any_instance.stub :refresh_feed do
      @user.refresh_feed_job_states << @job_state
    end

    login_user_for_feature @user
    visit read_path
    read_feed @feed, @user
  end
  
  it 'goes to start page after clicking on refresh', js: true do
    page.should_not have_css '#start-info'
    refresh_feed
    page.should have_css '#start-info'
  end

  context 'while refresh is running' do

    it 'shows message', js: true do
      refresh_feed
      within '#refresh-state-alerts' do
        page.should have_text 'Currently refreshing feed'
        page.should have_content @feed.title
      end
    end

    it 'shows messge after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-state-alerts' do
        page.should have_text 'Currently refreshing feed'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_state.reload.id
      page.should_not have_text 'Currently refreshing feed'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'Currently refreshing feed'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'opens folder in the sidebar when clicking on feed title', js: true do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed
      refresh_feed
      visit current_path

      folder_should_be_closed folder
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      folder_should_be_open folder
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'Currently refreshing feed'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'Currently refreshing feed'
    end

    it 'loads feed even if it has no unread entries', js: true do
      refresh_feed
      Entry.destroy_all
      subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
      subscription.update unread_entries: 0

      visit current_path
      unread_feed_entries_should_eq @feed, 0, @user
      within '#refresh-state-alerts' do
        page.should have_text 'Currently refreshing feed'
        page.should have_content @feed.title
      end
    end

  end

  context 'refresh finishes successfully' do

    before :each do
      User.any_instance.stub :find_refresh_feed_job_state do
        feed_subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
        feed_subscription.update unread_entries: feed_subscription.unread_entries + 1
        job_state = RefreshFeedJobState.where(user_id: @user.id, feed_id: @feed.id).first
        job_state.update state: RefreshFeedJobState::SUCCESS
        job_state
      end
    end

    it 'shows success alert', js: true do
      refresh_feed
      should_show_alert 'success-refresh-feed'
      within '#refresh-state-alerts' do
        page.should have_text 'Feed refreshed successfully'
        page.should have_content @feed.title
      end
    end

    it 'shows success message after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-state-alerts' do
        page.should have_text 'Feed refreshed successfully'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_state.reload.id
      page.should_not have_text 'Feed refreshed successfully'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'Feed refreshed successfully'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'opens folder in the sidebar when clicking on feed title', js: true do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed
      refresh_feed
      visit current_path

      folder_should_be_closed folder
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      folder_should_be_open folder
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'Feed refreshed successfully'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'Feed refreshed successfully'
    end

    it 'loads feed even if it has no unread entries', js: true do
      refresh_feed
      Entry.destroy_all
      subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
      subscription.update unread_entries: 0

      visit current_path
      unread_feed_entries_should_eq @feed, 0, @user
      within '#refresh-state-alerts' do
        page.should have_text 'Feed refreshed successfully'
        page.should have_content @feed.title
      end
    end

    it 'updates unread entries count', js: true do
      unread_feed_entries_should_eq @feed, 1, @user
      refresh_feed
      unread_feed_entries_should_eq @feed, 2, @user
    end
  end

  context 'refresh finishes with an error' do

    before :each do
      User.any_instance.stub :find_refresh_feed_job_state do
        feed_subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
        job_state = RefreshFeedJobState.where(user_id: @user.id, feed_id: @feed.id).first
        job_state.update state: RefreshFeedJobState::ERROR
        job_state
      end
    end

    it 'shows error alert', js: true do
      refresh_feed
      should_show_alert 'problem-refreshing'
      within '#refresh-state-alerts' do
        page.should have_text 'There\'s been an error trying to refresh feed'
        page.should have_content @feed.title
      end
    end

    it 'shows error message after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-state-alerts' do
        page.should have_text 'There\'s been an error trying to refresh feed'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_state.reload.id
      page.should_not have_text 'There\'s been an error trying to refresh feed'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'There\'s been an error trying to refresh feed'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'opens folder in the sidebar when clicking on feed title', js: true do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed
      refresh_feed
      visit current_path

      folder_should_be_closed folder
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      folder_should_be_open folder
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-state-#{@job_state.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'There\'s been an error trying to refresh feed'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'There\'s been an error trying to refresh feed'
    end

    it 'loads feed even if it has no unread entries', js: true do
      refresh_feed
      Entry.destroy_all
      subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
      subscription.update unread_entries: 0

      visit current_path
      unread_feed_entries_should_eq @feed, 0, @user
      within '#refresh-state-alerts' do
        page.should have_text 'There\'s been an error trying to refresh feed'
        page.should have_content @feed.title
      end
    end
  end

end