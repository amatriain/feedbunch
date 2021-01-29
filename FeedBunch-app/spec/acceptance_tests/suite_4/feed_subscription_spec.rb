# frozen_string_literal: true

require 'rails_helper'

describe 'subscription to feeds', type: :feature do

  before :each do
    @user = FactoryBot.create :user
    @feed1 = FactoryBot.create :feed
    @feed2 = FactoryBot.create :feed

    @entry1 = FactoryBot.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @entry2 = FactoryBot.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2

    @user.subscribe @feed1.fetch_url

    @job_state = FactoryBot.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed2.fetch_url
    allow_any_instance_of(User).to receive :enqueue_subscribe_job do |user|
      if user.id == @user.id
        user.subscribe_job_states << @job_state
      end
    end

    login_user_for_feature @user
    visit read_path
  end

  context 'display feeds' do

    it 'shows feeds the user is subscribed to', js: true do
      expect(page).to have_content @feed1.title
    end

    it 'does not show feeds the user is not subscribed to', js: true do
      expect(page).to have_no_content @feed2.title
    end
  end

  context 'add a feed subscription' do

    it 'goes to start page after adding a subscription', js: true do
      read_feed @feed1, @user
      expect(page).to have_no_css '#start-info'
      subscribe_feed @feed2.fetch_url
      expect(page).to have_css '#start-info'
    end

    context 'while subscription job is running' do

      it 'shows message', js: true do
        subscribe_feed @feed2.fetch_url
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Currently adding subscription to feed'
          expect(page).to have_content @feed2.fetch_url
        end
      end

      it 'shows message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Currently adding subscription to feed'
          expect(page).to have_content @feed2.fetch_url
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        expect(page).to have_no_text 'Currently adding subscription to feed'
        # alert should not be present after reloading
        visit current_path
        expect(page).to have_no_text 'Currently adding subscription to feed'
      end

    end

    context 'subscription job finishes successfully' do

      before :each do
        allow_any_instance_of(User).to receive :find_subscribe_job_state do |user|
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
          expect(page).to have_text 'Successfully added subscription to feed'
          expect(page).to have_content @feed2.title
        end
      end

      it 'shows success message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Successfully added subscription to feed'
          expect(page).to have_content @feed2.title
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        expect(page).to have_no_text 'Successfully added subscription to feed'
        # alert should not be present after reloading
        visit current_path
        expect(page).to have_no_text 'Successfully added subscription to feed'
      end

      it 'opens feed entries when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url
        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        expect(page).to have_text @entry2.title
      end

      it 'opens folder in the sidebar when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url

        # Move feed to folder and reload page. Folder should be closed after reload
        folder_title = 'new folder'
        move_feed_to_new_folder @feed2, folder_title, @user
        folder = @user.folders.find_by title: folder_title
        visit current_path
        folder_should_be_closed folder

        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        folder_should_be_open folder
      end

      it 'permanently dismisses alert when clicking on feed title', js: true do
        subscribe_feed @feed2.fetch_url
        find("#subscribe-state-#{@job_state.reload.id} a.job-feed-title").click
        go_to_start_page
        expect(page).to have_no_text 'Successfully added subscription to feed'
        # alert should not be present after logout and login
        logout_user_for_feature
        login_user_for_feature @user
        go_to_start_page
        expect(page).to have_no_text 'Successfully added subscription to feed'
      end

      it 'loads feed even if it has no unread entries', js: true do
        subscribe_feed @feed2.fetch_url
        expect(page).to have_text 'Successfully added subscription to feed'
        unread_feed_entries_should_eq @feed2, 1, @user
        Entry.destroy_all
        subscription = FeedSubscription.find_by user_id: @user.id, feed_id: @feed2.id
        subscription.update unread_entries: 0

        visit current_path
        unread_feed_entries_should_eq @feed2, 0, @user
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Successfully added subscription to feed'
          expect(page).to have_content @feed2.title
        end
      end

    end

    context 'subscription job finishes with an error' do

      before :each do
        allow_any_instance_of(User).to receive :find_subscribe_job_state do |user|
          if user.id == @user.id
            @job_state.update state: SubscribeJobState::ERROR
            @job_state
          end
        end
      end

      it 'shows error alert', js: true do
        subscribe_feed @feed2.fetch_url
        should_show_alert 'problem-subscribing'
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Unable to add subscription to feed'
          expect(page).to have_content @feed2.fetch_url
        end
      end

      it 'shows error message after reloading', js: true do
        subscribe_feed @feed2.fetch_url
        visit current_path
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Unable to add subscription to feed'
          expect(page).to have_content @feed2.fetch_url
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @feed2.fetch_url
        close_subscribe_job_alert @job_state.reload.id
        expect(page).to have_no_text 'Unable to add subscription to feed'
        # alert should not be present after reloading
        visit current_path
        expect(page).to have_no_text 'Unable to add subscription to feed'
      end

    end

    context 'blacklisted url' do

      before :each do
        @blacklisted_url = 'some.aede.bastard.com'
        allow_any_instance_of(User).to receive :enqueue_subscribe_job do |user, url|
          @job_state_2 = FactoryBot.build :subscribe_job_state,
                                          user_id: @user.id,
                                          fetch_url: @blacklisted_url,
                                          state: SubscribeJobState::ERROR
          @user.subscribe_job_states << @job_state_2
          raise BlacklistedUrlError.new
        end
      end

      it 'shows error alert', js: true do
        subscribe_feed @blacklisted_url
        should_show_alert 'blacklisted-url'
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Unable to add subscription to feed'
          expect(page).to have_content @blacklisted_url
        end
      end

      it 'shows error message after reloading', js: true do
        subscribe_feed @blacklisted_url
        visit current_path
        within '#subscribe-state-alerts' do
          expect(page).to have_text 'Unable to add subscription to feed'
          expect(page).to have_content @blacklisted_url
        end
      end

      it 'dismisses alert permanently', js: true do
        subscribe_feed @blacklisted_url
        close_subscribe_job_alert @job_state_2.reload.id
        expect(page).to have_no_text 'Unable to add subscription to feed'
        # alert should not be present after reloading
        visit current_path
        expect(page).to have_no_text 'Unable to add subscription to feed'
      end
    end

  end

end
