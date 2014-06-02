require 'spec_helper'

describe 'subscription to feeds' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed

    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2

    @user.subscribe @feed1.fetch_url

    @job_state = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed2.fetch_url
    User.any_instance.stub :enqueue_subscribe_job do |user|
      if user.id == @user.id
        user.subscribe_job_states << @job_state
      end
    end

    login_user_for_feature @user
    visit read_path
  end

  context 'display feeds' do

    it 'shows feeds the user is subscribed to', js: true do
      page.should have_content @feed1.title
    end

    it 'does not show feeds the user is not subscribed to' do
      page.should_not have_content @feed2.title
    end
  end

  context 'add a feed subscription' do

    it 'goes to start page after adding a subscription', js: true do
      read_feed @feed1, @user
      page.should_not have_css '#start-info'
      subscribe_feed @feed2.fetch_url
      page.should have_css '#start-info'
    end

    context 'while subscription job is running' do

      it 'shows message', js: true do
        subscribe_feed @feed2.fetch_url
        within '#subscribe-state-alerts' do
          page.should have_text 'Currently adding subscription to feed'
          page.should have_content @feed2.fetch_url
        end
      end

      it 'shows message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          page.should have_text 'Currently adding subscription to feed'
          page.should have_content @feed2.fetch_url
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        page.should_not have_text 'Currently adding subscription to feed'
        # alert should not be present after reloading
        visit current_path
        page.should_not have_text 'Currently adding subscription to feed'
      end

    end

    context 'subscription job finishes successfully' do

      before :each do
        User.any_instance.stub :find_subscribe_job_state do |user|
          if user.id == @user.id && @job_state.reload.state != SubscribeJobState::SUCCESS
            user.subscribe @feed2.fetch_url
            @job_state.update state: SubscribeJobState::SUCCESS, feed_id: @feed2.id
          end
          @job_state
        end
      end

      it 'shows success alert', js: true do
        subscribe_feed @feed2.fetch_url
        should_show_alert 'success-subscribe-feed'
        within '#subscribe-state-alerts' do
          page.should have_text 'Successfully added subscription to feed'
          page.should have_content @feed2.title
        end
      end

      it 'shows success message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          page.should have_text 'Successfully added subscription to feed'
          page.should have_content @feed2.title
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        page.should_not have_text 'Successfully added subscription to feed'
        # alert should not be present after reloading
        visit current_path
        page.should_not have_text 'Successfully added subscription to feed'
      end

      it 'opens feed entries when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url
        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        page.should have_text @entry2.title
      end

      it 'opens folder in the sidebar when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url

        # Move feed to folder and reload page. Folder should be closed after reload
        folder_title = 'new folder'
        move_feed_to_new_folder @feed2, folder_title, @user
        folder = @user.folders.where(title: folder_title).first
        visit current_path
        folder_should_be_closed folder

        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        folder_should_be_open folder
      end

      it 'permanently dismisses alert when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url
        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        go_to_start_page
        page.should_not have_text 'Successfully added subscription to feed'
        # alert should not be present after logout and login
        logout_user
        login_user_for_feature @user
        go_to_start_page
        page.should_not have_text 'Successfully added subscription to feed'
      end

      it 'loads feed even if it has no unread entries', js: true do
        subscribe_feed @feed2.fetch_url
        page.should have_text 'Successfully added subscription to feed'
        Entry.destroy_all
        subscription = FeedSubscription.where(user_id: @user.id, feed_id: @feed2.id).first
        subscription.update unread_entries: 0

        visit current_path
        unread_feed_entries_should_eq @feed2, 0, @user
        within '#subscribe-state-alerts' do
          page.should have_text 'Successfully added subscription to feed'
          page.should have_content @feed2.title
        end
      end

    end

    context 'subscription job finishes with an error' do

      before :each do
        User.any_instance.stub :find_subscribe_job_state do |user|
          if user.if == @user.id
            @job_state.update state: SubscribeJobState::ERROR
            @job_state
          end
        end
      end

      it 'shows error alert', js: true do
        subscribe_feed @feed2.fetch_url
        should_show_alert 'problem-subscribing'
        within '#subscribe-state-alerts' do
          page.should have_text 'Unable to add subscription to feed'
          page.should have_content @feed2.fetch_url
        end
      end

      it 'shows error message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          page.should have_text 'Unable to add subscription to feed'
          page.should have_content @feed2.fetch_url
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        page.should_not have_text 'Unable to add subscription to feed'
        # alert should not be present after reloading
        visit current_path
        page.should_not have_text 'Unable to add subscription to feed'
      end

    end
  end

end
