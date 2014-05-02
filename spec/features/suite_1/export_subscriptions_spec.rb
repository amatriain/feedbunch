require 'spec_helper'

describe 'export subscriptions' do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
    visit read_path
  end

  after :each do
    # Close the browser as soon as test is finished. Otherwise the javascript running in the client sometimes
    # tries to retrieve JSON (e.g. opml_export_job_states) while test cleanup is happening, which sometimes gives weird
    # errors (because a model instance has been deleted right in the middle of a controller action processing).
    page.execute_script "window.close();"
  end

  it 'shows export subscriptions link in edit profile page', js: true do
    visit edit_user_registration_path
    within "a[href*='#{api_opml_exports_path}'][data-method='post']", visible: true do
      page.should have_text 'Export subscriptions'
    end
  end

  context 'error management' do

    it 'redirects to start page if there is an error enqueuing the export job', js: true do
      User.any_instance.stub(:export_subscriptions).and_raise StandardError.new

      export_subscriptions

      current_path.should eq read_path
    end
  end

  context 'user requests an export of his subscriptions' do

    before :each do
      export_subscriptions
      page.should have_text 'Your feed subscriptions are being exported'
    end

    it 'redirects to start page', js: true do
      current_path.should eq read_path
      page.should have_css '#start-info'
    end

    it 'shows error message', js: true do
      @user.reload.opml_export_job_state.update! state: OpmlExportJobState::ERROR

      visit current_path
      page.should have_content 'There\'s been an error trying to export your feed subscriptions'
    end

    it 'shows success message', js: true do
      @user.reload.opml_export_job_state.update! state: OpmlExportJobState::SUCCESS, filename: OPMLExporter::FILENAME

      visit read_path
      page.should have_content 'Your feed subscriptions were successfully exported'
    end

    it 'changes message when export finishes successfully', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::SUCCESS, filename: OPMLExporter::FILENAME
      page.should have_content 'Your feed subscriptions have been successfully exported'
    end

    it 'shows alert when export finishes successfully', js: true do
      read_feed @feed, @user
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::SUCCESS, filename: OPMLExporter::FILENAME
      should_show_alert 'export-process-success'
    end

    it 'changes message when export finishes with an error', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::ERROR
      page.should have_content 'There\'s been an error trying to export your feed subscriptions'
    end

    it 'shows alert when export finishes with an error', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::ERROR
      should_show_alert 'export-process-error'
    end
  end

  context 'hide alert' do

    it 'does not show an alert in the start page when the user has never ran an OPML export', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::NONE
      visit read_path
      page.should_not have_css '#export-process-state'
    end

    it 'hides export data alert when the export finished with an error', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::ERROR
      visit read_path
      page.should have_content 'There\'s been an error trying to export your feed subscriptions'
      close_export_alert

      # alert immediately disappears
      page.should_not have_content 'There\'s been an error trying to export your feed subscriptions'
      # alert is not displayed on page reload
      visit read_path
      page.should have_css '#start-info #export-process-state.ng-hide', visible: false
      page.should_not have_content 'There\'s been an error trying to export your feed subscriptions'
    end

    it 'hides import data alert when the export finished successfully', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::SUCCESS, filename: OPMLExporter::FILENAME
      visit read_path
      page.should have_content 'Your feed subscriptions were successfully exported'
      close_export_alert

      # alert immediately disappears
      page.should_not have_content 'Your feed subscriptions have been successfully exported'
      # alert is not displayed on page reload
      visit read_path
      page.should have_css '#start-info #export-process-state.ng-hide', visible: false
      page.should_not have_content 'Your feed subscriptions have been successfully exported'
    end

    it 'cannot hide export data alert while the export is running', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::RUNNING
      visit read_path
      page.should have_content 'Your feed subscriptions are being exported'
      page.should_not have_css '#start-info #export-process-state button.close', visible: true
    end
  end

  context 'file download' do

    before :each do
      export_subscriptions
      page.should have_text 'Your feed subscriptions are being exported'
      @opml_data = File.read File.join(__dir__, '..', '..', 'attachments', 'subscriptions.xml')
      Feedbunch::Application.config.uploads_manager.stub(:read).and_return @opml_data
      Feedbunch::Application.config.uploads_manager.stub(:exists?).and_return true
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::SUCCESS, filename: OPMLExporter::FILENAME
    end

    it 'downloads OPML file from alert link', js: true do
      visit read_path
      find('a#download-opml-export').click

      page.response_headers['Content-Type'].should eq 'application/xml'
      page.body.should eq @opml_data
    end

    it 'downloads OPML file from edit registration view', js: true do
      visit edit_user_registration_path
      find('a#download-opml-export').click

      page.response_headers['Content-Type'].should eq 'application/xml'
      page.body.should eq @opml_data
    end

    it 'shows alert when the OPML file does not exist', js: true do
      Feedbunch::Application.config.uploads_manager.stub(:read).and_raise OpmlExportDoesNotExistError.new
      Feedbunch::Application.config.uploads_manager.stub(:exists?).and_return false

      visit read_path
      find('a#download-opml-export').click

      page.should have_text 'Cannot download OPML export file. Please export your subscriptions again.'
    end

    it 'does not show download link if job is not in state SUCCESS', js: true do
      @user.reload.opml_export_job_state.update state: OpmlExportJobState::NONE
      visit read_path
      page.should_not have_css 'a#download-opml-export'
      visit edit_user_registration_path
      page.should_not have_css 'a#download-opml-export'

      @user.reload.opml_export_job_state.update state: OpmlExportJobState::RUNNING
      visit read_path
      page.should_not have_css 'a#download-opml-export'
      visit edit_user_registration_path
      page.should_not have_css 'a#download-opml-export'

      @user.reload.opml_export_job_state.update state: OpmlExportJobState::ERROR
      visit read_path
      page.should_not have_css 'a#download-opml-export'
      visit edit_user_registration_path
      page.should_not have_css 'a#download-opml-export'
    end
  end
end