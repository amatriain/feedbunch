require 'spec_helper'

describe 'import subscriptions', type: :feature do
  before :each do
    @data_file = File.join __dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip'

    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
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
    page.should have_css '#opml-import-popup', visible: true
  end

  context 'upload button in edit profile view' do

    before :each do
      visit edit_user_registration_path
    end

    it 'show button if the user has never run an import', js: true do
      page.should have_css 'a#opml-import-button', visible: true
    end

    it 'shows button if user has an errored import', js: true do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::ERROR
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      page.should have_css 'a#opml-import-button', visible: true
    end

    it 'does not show button if user has a running import', js: true do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      page.should_not have_css 'a#opml-import-button', visible: true
      page.should have_text 'Your feed subscriptions are currently being imported'
    end

    it 'shows button if user has a successful import', js: true do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::SUCCESS
      @user.opml_import_job_state = opml_import_job_state
      visit edit_user_registration_path
      page.should have_css 'a#opml-import-button', visible: true
    end

  end

  context 'error management' do

    it 'redirects to start page if there is an error submitting the form', js: true do
      User.any_instance.stub(:import_subscriptions).and_raise StandardError.new

      find('a#start-opml-import').click
      page.should have_css '#opml_import_file'
      attach_file 'opml_import_file', @data_file
      find('#opml-import-submit').click

      current_path.should eq read_path
    end
  end

  context 'user uploads file' do

    before :each do
      find('a#start-opml-import').click
      page.should have_css '#opml_import_file'
      attach_file 'opml_import_file', @data_file
      find('#opml-import-submit').click
      page.should have_text 'Your feed subscriptions are being imported'
    end

    after :each do
      uploaded_files = File.join Rails.root, 'uploads', '*.opml'
      Dir.glob(uploaded_files).each {|f| File.delete f}
    end

    it 'redirects to start page', js: true do
      current_path.should eq read_path
      page.should have_css '#start-info'
    end

    it 'shows error message', js: true do
      @user.reload.opml_import_job_state.update! state: OpmlImportJobState::ERROR

      visit current_path
      page.should have_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'shows success message', js: true do
      @user.reload.opml_import_job_state.update! state: OpmlImportJobState::SUCCESS

      visit read_path
      page.should have_content 'Your feed subscriptions have been successfully imported'
    end

    it 'shows import process progress', js: true do
      page.should have_content 'Your feed subscriptions are being imported'
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update total_feeds: 412
      opml_import_job_state.update processed_feeds: 77
      page.should have_content 'Subscriptions imported: 77 of 412'
    end

    it 'changes message when import finishes successfully', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      page.should have_content 'Your feed subscriptions have been successfully imported'
    end

    it 'shows alert when import finishes successfully', js: true do
      read_feed @feed, @user
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      should_show_alert 'import-process-success'
    end

    it 'shows new feeds and folders when import finishes successfully', js: true do
      read_feed @feed, @user
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      @user.subscribe feed.fetch_url
      folder.feeds << feed
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      within '#sidebar #folders-list' do
        page.should have_css "#folder-#{folder.id}"
      end
      within "#sidebar #folders-list #folder-#{folder.id}" do
        page.should have_css "a[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: false
      end
    end

    it 'changes message when import finishes with an error', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::ERROR
      page.should have_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'shows alert when import finishes with an error', js: true do
      opml_import_job_state = @user.reload.opml_import_job_state
      opml_import_job_state.update state: OpmlImportJobState::ERROR
      should_show_alert 'import-process-error'
    end
  end

  context 'hide alert' do

    it 'hides import data alert when the user has never ran an OPML import', js: true do
      page.should have_content 'If you want to import your feed subscriptions from another feed aggregator'
      close_import_alert

      # alert immediately disappears
      page.should_not have_content 'If you want to import your feed subscriptions from another feed aggregator'
      # alert is not displayed on page reload
      visit read_path
      page.should have_css '#start-info #import-process-state.ng-hide', visible: false
      page.should_not have_content 'If you want to import your feed subscriptions from another feed aggregator'
    end

    it 'hides import data alert when the import finished with an error', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::ERROR
      visit read_path
      page.should have_content 'There\'s been an error trying to import your feed subscriptions'
      close_import_alert

      # alert immediately disappears
      page.should_not have_content 'There\'s been an error trying to import your feed subscriptions'
      # alert is not displayed on page reload
      visit read_path
      page.should have_css '#start-info #import-process-state.ng-hide', visible: false
      page.should_not have_content 'There\'s been an error trying to import your feed subscriptions'
    end

    it 'hides import data alert when the import finished successfully', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      visit read_path
      page.should have_content 'Your feed subscriptions have been successfully imported'
      close_import_alert

      # alert immediately disappears
      page.should_not have_content 'Your feed subscriptions have been successfully imported'
      # alert is not displayed on page reload
      visit read_path
      page.should have_css '#start-info #import-process-state.ng-hide', visible: false
      page.should_not have_content 'Your feed subscriptions have been successfully imported'
    end

    it 'cannot hide import data alert while the import is running', js: true do
      @user.reload.opml_import_job_state.update state: OpmlImportJobState::RUNNING
      visit read_path
      page.should have_content 'Your feed subscriptions are being imported'
      page.should_not have_css '#start-info #import-process-state button.close', visible: true
    end
  end
end