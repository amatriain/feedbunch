# frozen_string_literal: true

require 'rails_helper'

describe 'import subscriptions', type: :feature do
  before :each do
    @data_file = File.absolute_path File.join(__dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip')

    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @entry = FactoryBot.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
    visit read_path
    find('#start-page').click
  end

  after :each do
    # Close the browser as soon as test is finished. Otherwise the javascript running in the client sometimes
    # tries to retrieve JSON (e.g. opml_import_job_states) while test cleanup is happening, which sometimes gives weird
    # errors (because a model instance has been deleted right in the middle of a controller action processing).
    page.execute_script "window.close();"
  end

  it 'shows file upload popup', js: true do
    find('a#start-opml-import').click
    expect(page).to have_css '#opml-import-popup', visible: true
  end

  context 'upload button in edit profile view' do

    before :each do
      visit edit_user_registration_path
    end

    it 'show button if the user has never run an import', js: true do
      expect(page).to have_css 'a#opml-import-button', visible: true
    end

    it 'shows button if user has an errored import', js: true do
      opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::ERROR
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      expect(page).to have_css 'a#opml-import-button', visible: true
    end

    it 'does not show button if user has a running import', js: true do
      opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      expect(page).to have_no_css 'a#opml-import-button', visible: true
      expect(page).to have_text 'Your feed subscriptions are currently being imported'
    end

    it 'shows button if user has a successful import', js: true do
      opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::SUCCESS
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      expect(page).to have_css 'a#opml-import-button', visible: true
    end

  end

  context 'error management' do

    it 'redirects to start page if there is an error submitting the form', js: true do
      allow_any_instance_of(User).to receive(:import_subscriptions).and_raise StandardError.new

      find('a#start-opml-import').click
      expect(page).to have_css '#opml_import_file'
      attach_file 'opml_import_file', @data_file
      find('#opml-import-submit').click

      expect(current_path).to eq read_path
    end
  end

  context 'user uploads file' do

    before :each do
      find('a#start-opml-import').click
      expect(page).to have_css '#opml_import_file'
      attach_file 'opml_import_file', @data_file
      find('#opml-import-submit').click
      expect(page).to have_text 'Your feed subscriptions are being imported'
    end

    after :each do
      uploaded_files = File.join Rails.root, 'uploads', '*.opml'
      Dir.glob(uploaded_files).each {|f| File.delete f}
    end

    it 'redirects to start page', js: true do
      expect(current_path).to eq read_path
      expect(page).to have_css '#start-info'
    end

    it 'shows error message', js: true do
      @user.reload.opml_import_job_state.update! state: OpmlImportJobState::ERROR

      visit current_path
      expect(page).to have_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'shows success message', js: true do
      @user.reload.opml_import_job_state.update! state: OpmlImportJobState::SUCCESS

      visit read_path
      expect(page).to have_content 'Your feed subscriptions have been successfully imported'
    end

    it 'shows import process progress', js: true do
      expect(page).to have_content 'Your feed subscriptions are being imported'
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update total_feeds: 412
      opml_import_job_state.update processed_feeds: 77
      expect(page).to have_content 'Subscriptions imported: 77 of 412'
    end

    it 'changes message when import finishes successfully', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      expect(page).to have_content 'Your feed subscriptions have been successfully imported'
    end

    it 'shows URLs of failed feeds when import finishes successfully', js: true do
      failed_url_1 = 'http://failed_url_1.com'
      failed_url_2 = 'http://failed_url_2.com'
      opml_import_job_state = @user.reload.opml_import_job_state
      import_failure_1 = FactoryBot.build :opml_import_failure,
                                           opml_import_job_state_id: opml_import_job_state.id,
                                           url: failed_url_1
      import_failure_2 = FactoryBot.build :opml_import_failure,
                                           opml_import_job_state_id: opml_import_job_state.id,
                                           url: failed_url_2
      opml_import_job_state.opml_import_failures << import_failure_1 << import_failure_2

      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      expect(find '#import-process-state ul').to have_content failed_url_1
      expect(find '#import-process-state ul').to have_content failed_url_2
    end

    it 'shows alert when import finishes successfully', js: true do
      read_feed @feed, @user
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      should_show_alert 'import-process-success'
    end

    it 'shows new feeds and folders when import finishes successfully', js: true do
      read_feed @feed, @user
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      feed = FactoryBot.create :feed
      entry = FactoryBot.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url
      folder.feeds << feed
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      within '#sidebar #folders-list' do
        expect(page).to have_css "#folder-#{folder.id}"
      end
      within "#sidebar #folders-list #folder-#{folder.id}" do
        expect(page).to have_css "a[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: false
      end
    end

    it 'updates stats in start page when import finishes successfully', js: true do
      feed1 = FactoryBot.create :feed
      entry1 = FactoryBot.build :entry, feed_id: feed1.id
      feed1.entries << entry1

      feed2 = FactoryBot.create :feed
      entry2 = FactoryBot.build :entry, feed_id: feed2.id
      entry3 = FactoryBot.build :entry, feed_id: feed2.id
      feed1.entries << entry2 << entry3

      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url

      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS

      expect(page).to have_content 'Subscribed to 3 feeds with 4 unread entries'
    end

    it 'changes message when import finishes with an error', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::ERROR
      expect(page).to have_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'shows alert when import finishes with an error', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::ERROR
      should_show_alert 'import-process-error'
    end
  end

  context 'hide alert' do

    it 'hides import data alert when the user has never ran an OPML import', js: true do
      expect(page).to have_content 'If you want to import your feed subscriptions from another feed aggregator'
      close_import_alert

      # alert immediately disappears
      expect(page).to have_no_content 'If you want to import your feed subscriptions from another feed aggregator'
      # alert is not displayed on page reload
      visit read_path
      expect(page).to have_css '#start-info #import-process-state.ng-hide', visible: false
      expect(page).to have_no_content 'If you want to import your feed subscriptions from another feed aggregator'
    end

    it 'hides import data alert when the import finished with an error', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::ERROR
      visit read_path
      expect(page).to have_content 'There\'s been an error trying to import your feed subscriptions'
      close_import_alert

      # alert immediately disappears
      expect(page).to have_no_content 'There\'s been an error trying to import your feed subscriptions'
      # alert is not displayed on page reload
      visit read_path
      expect(page).to have_css '#start-info #import-process-state.ng-hide', visible: false
      expect(page).to have_no_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'hides import data alert when the import finished successfully', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      visit read_path
      expect(page).to have_content 'Your feed subscriptions have been successfully imported'
      close_import_alert

      # alert immediately disappears
      expect(page).to have_no_content 'Your feed subscriptions have been successfully imported'
      # alert is not displayed on page reload
      visit read_path
      expect(page).to have_css '#start-info #import-process-state.ng-hide', visible: false
      expect(page).to have_no_content 'Your feed subscriptions have been successfully imported'
    end

    it 'cannot hide import data alert while the import is running', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::RUNNING
      visit read_path
      expect(page).to have_content 'Your feed subscriptions are being imported'
      expect(page).to have_no_css '#start-info #import-process-state button.close', visible: true
    end
  end
end