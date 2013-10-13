require 'spec_helper'

describe 'import subscriptions' do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
    visit read_path
    find('#start-page').click
    open_user_menu
  end

  it 'shows file upload popup', js: true do
    find('a#start-data-import').click
    page.should have_css '#data-import-popup', visible: true
  end

  context 'upload link in dropdown' do

    it 'show link if the user has never run an import', js: true do
      page.should have_css '.navbar a#nav-data-import', visible: true
    end

    it 'shows link if user has an errored import', js: true do
      data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::ERROR
      @user.data_import = data_import
      visit read_path
      open_user_menu
      page.should have_css '.navbar a#nav-data-import', visible: true
    end

    it 'does not show link if user has a running import', js: true do
      data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::RUNNING
      @user.data_import = data_import
      visit read_path
      open_user_menu
      page.should_not have_css '.navbar a#nav-data-import', visible: true
    end

    it 'shows link if user has a successful import', js: true do
      data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::SUCCESS
      @user.data_import = data_import
      visit read_path
      open_user_menu
      page.should have_css '.navbar a#nav-data-import', visible: true
    end

    it 'opens popup even if user is not in feeds index view', js: true do
      visit edit_user_registration_path
      open_user_menu
      page.should have_css '.navbar a#nav-data-import'
      find('.navbar a#nav-data-import').click
      page.should have_css '#data-import-popup', visible: true
    end

  end

  context 'user uploads file' do

    before :each do
      @data_file = File.join __dir__, '..', 'attachments', 'feedbunch@gmail.com-takeout.zip'
      find('a#start-data-import').click
      page.should have_css '#data_import_file'
      attach_file 'data_import_file', @data_file
      find('#data-import-submit').click
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

    it 'redirects to start page if there is an error submitting the form', js: true do
      User.any_instance.stub(:import_subscriptions).and_raise StandardError.new
      @user.data_import.destroy
      visit read_path
      open_user_menu

      find('a#start-data-import').click
      page.should have_css '#data_import_file'
      attach_file 'data_import_file', @data_file
      find('#data-import-submit').click

      current_path.should eq read_path
    end

    it 'shows error message', js: true do
      data_import = @user.data_import
      data_import.status = DataImport::ERROR
      data_import.save!

      visit read_path

      page.should have_content 'There\'s been an error importing your subscriptions'
    end

    it 'shows success message', js: true do
      data_import = @user.data_import
      data_import.status = DataImport::SUCCESS
      data_import.save!

      visit read_path

      page.should have_content 'Your subscriptions have been successfully imported into Feedbunch'
    end

    it 'shows import process progress', js: true do
      page.should have_content 'Your subscriptions are being imported into Feedbunch'
      @user.data_import.total_feeds = 412
      @user.data_import.processed_feeds = 77
      @user.data_import.save
      page.should have_content 'Feeds imported: 77 of 412'
    end

    it 'changes message when import finishes successfully', js: true do
      @user.data_import.status = DataImport::SUCCESS
      @user.data_import.save
      page.should have_content 'Your subscriptions have been successfully imported into Feedbunch'
    end

    it 'shows alert when import finishes successfully', js: true do
      read_feed @feed.id
      @user.data_import.status = DataImport::SUCCESS
      @user.data_import.save
      page.should have_content 'Your subscribed feeds have been imported into Feedbunch'
    end

    it 'shows new feeds and folders when import finishes successfully', js: true do
      read_feed @feed.id
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed = FactoryGirl.create :feed
      @user.subscribe feed.fetch_url
      folder.feeds << feed
      @user.data_import.status = DataImport::SUCCESS
      @user.data_import.save
      within '#sidebar #folders-list' do
        page.should have_css "#folder-#{folder.id}"
      end
      within "#sidebar #folders-list #folder-#{folder.id}" do
        page.should have_css "a[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: false
      end
    end

    it 'changes message when import finishes with an error', js: true do
      @user.data_import.status = DataImport::ERROR
      @user.data_import.save
      page.should have_content 'There\'s been an error importing your subscriptions'
    end

    it 'shows alert when import finishes with an error', js: true do
      read_feed @feed.id
      @user.data_import.status = DataImport::ERROR
      @user.data_import.save
      page.should have_content 'There has been an error while trying to import your subscribed feeds into Feedbunch'
    end
  end
end