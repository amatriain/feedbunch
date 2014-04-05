require 'spec_helper'

describe 'refresh feeds' do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    @user.subscribe @feed.fetch_url

    @job_status = FactoryGirl.build :refresh_feed_job_status, user_id: @user.id, feed_id: @feed.id
    User.any_instance.stub :refresh_feed do
      @user.refresh_feed_job_statuses << @job_status
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
      within '#refresh-status-alerts' do
        page.should have_text 'Currently refreshing feed'
        page.should have_content @feed.title
      end
    end

    it 'shows messge after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-status-alerts' do
        page.should have_text 'Currently refreshing feed'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_status.reload.id
      page.should_not have_text 'Currently refreshing feed'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'Currently refreshing feed'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'Currently refreshing feed'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'Currently refreshing feed'
    end
  end

  context 'refresh finishes successfully' do

    before :each do
      User.any_instance.stub :find_refresh_feed_job_status do
        feed_subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
        feed_subscription.update unread_entries: feed_subscription.unread_entries + 1
        job_status = RefreshFeedJobStatus.where(user_id: @user.id, feed_id: @feed.id).first
        job_status.update status: RefreshFeedJobStatus::SUCCESS
        job_status
      end
    end

    it 'shows success alert', js: true do
      refresh_feed
      should_show_alert 'success-refresh-feed'
      within '#refresh-status-alerts' do
        page.should have_text 'Feed refreshed successfully'
        page.should have_content @feed.title
      end
    end

    it 'shows success message after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-status-alerts' do
        page.should have_text 'Feed refreshed successfully'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_status.reload.id
      page.should_not have_text 'Feed refreshed successfully'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'Feed refreshed successfully'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'Feed refreshed successfully'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'Feed refreshed successfully'
    end
  end

  context 'refresh finishes with an error' do

    before :each do
      User.any_instance.stub :find_refresh_feed_job_status do
        feed_subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed.id).first
        job_status = RefreshFeedJobStatus.where(user_id: @user.id, feed_id: @feed.id).first
        job_status.update status: RefreshFeedJobStatus::ERROR
        job_status
      end
    end

    it 'shows error alert', js: true do
      refresh_feed
      should_show_alert 'problem-refreshing'
      within '#refresh-status-alerts' do
        page.should have_text 'There\'s been an error trying to refresh feed'
        page.should have_content @feed.title
      end
    end

    it 'shows error message after refreshing', js: true do
      refresh_feed
      visit current_path
      within '#refresh-status-alerts' do
        page.should have_text 'There\'s been an error trying to refresh feed'
        page.should have_content @feed.title
      end
    end

    it 'dismisses alert permanently', js: true do
      refresh_feed
      close_refresh_feed_job_alert @job_status.reload.id
      page.should_not have_text 'There\'s been an error trying to refresh feed'
      # alert should not be present after refreshing
      visit current_path
      page.should_not have_text 'There\'s been an error trying to refresh feed'
    end

    it 'opens feed entries when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      page.should have_text @entry.title
    end

    it 'permanently dismisses alert when clicking on feed title', js: true do
      refresh_feed
      find("#refresh-status-#{@job_status.reload.id} a.job-feed-title").click
      go_to_start_page
      page.should_not have_text 'There\'s been an error trying to refresh feed'
      # alert should not be present after reloading page
      visit current_path
      page.should_not have_text 'There\'s been an error trying to refresh feed'
    end
  end


# TODO: remove the following tests, they come from an old version of the refresh process.

  it 'refreshes a single feed', js: true do
    # Page should have current entries for the feed
    page.should have_content @entry.title

    # Refresh feed
    entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    FeedClient.should_receive(:fetch).with @feed, anything
    @feed.entries << entry2
    refresh_feed

    # Page should have the new entries for the feed
    page.should have_content @entry.title
    page.should have_content entry2.title
  end

  it 'only shows unread entries when refreshing a single feed', js: true do
    entry2 = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << entry2
    # @entry is read, entry2 is unread
    entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
    entry_state1.read = true
    entry_state1.save!
    # When refreshing the feed, fetch the new unread entry3
    entry3 = FactoryGirl.build :entry, feed_id: @feed.id
    FeedClient.stub :fetch do
      @feed.entries << entry3
    end

    read_feed @feed, @user
    refresh_feed

    # entry2 and entry3 should appear, @entry should not appear because it's already read
    page.should_not have_content @entry.title
    page.should have_content entry2.title
    page.should have_content entry3.title
  end

  it 'shows an alert if there is a problem refreshing a feed', js: true do
    FeedClient.stub(:fetch).and_raise StandardError.new
    refresh_feed

    should_show_alert 'problem-refreshing'
  end

  # Regression test for bug #169
  it 'does not show an alert refreshing a feed without unread entries', js: true do
    FeedClient.stub :fetch
    entry_state = EntryState.where(entry_id: @entry.id, user_id: @user.id).first
    entry_state.read=true
    entry_state.save

    refresh_feed

    should_hide_alert 'problem-refreshing'
  end

end