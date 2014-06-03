require 'spec_helper'

describe ImportSubscriptionsJob do

  before :each do
    # Ensure files are not deleted, we will need them for running tests again!
    File.stub(:delete).and_return 1

    @user = FactoryGirl.create :user
    @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.opml_import_job_state = @opml_import_job_state

    @filename = '1371324422.opml'
    @filepath = File.join __dir__, '..', '..', 'attachments', @filename
    @file_contents = File.read @filepath

    Feedbunch::Application.config.uploads_manager.stub :read do |user, folder, filename|
      user.should eq @user
      if filename == @filename
        @file_contents
      else
        nil
      end
    end
    Feedbunch::Application.config.uploads_manager.stub :save
    Feedbunch::Application.config.uploads_manager.stub :delete
  end

  it 'updates the data import total number of feeds' do
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.opml_import_job_state.total_feeds.should eq 4
  end

  it 'sets data import state to ERROR if the file does not exist' do
    expect {ImportSubscriptionsJob.perform 'not.a.real.file', @user.id}.to raise_error OpmlImportError
    @user.reload
    @user.opml_import_job_state.state.should eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not well formed XML' do
    not_valid_xml_filename = File.join __dir__, '..', '..', 'attachments', 'not-well-formed-xml.opml'
    file_contents = File.read not_valid_xml_filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents
    expect {ImportSubscriptionsJob.perform not_valid_xml_filename, @user.id}.to raise_error Nokogiri::XML::SyntaxError
    @user.reload
    @user.opml_import_job_state.state.should eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not valid OPML' do
    not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
    file_contents = File.read not_valid_opml_filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents
    expect {ImportSubscriptionsJob.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
    @user.reload
    @user.opml_import_job_state.state.should eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if an error is raised' do
    OPMLImporter.stub(:import).and_raise StandardError.new
    expect {ImportSubscriptionsJob.perform @filename, @user.id}.to raise_error
    @user.reload
    @user.opml_import_job_state.state.should eq OpmlImportJobState::ERROR
  end

  it 'does nothing if the user does not exist' do
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, 1234567890
  end

  it 'reads uploaded file' do
    Feedbunch::Application.config.uploads_manager.should_receive(:read).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'enqueues jobs to subscribe the user to feeds' do
    folder_linux = FactoryGirl.build :folder, user_id: @user.id, title: 'Linux'
    folder_webcomics = FactoryGirl.build :folder, user_id: @user.id, title: 'Webcomics'
    @user.folders << folder_linux << folder_webcomics

    Resque.should_receive(:enqueue).with SubscribeUserJob, @user.id, 'http://brakemanscanner.org/atom.xml', nil, true, nil
    Resque.should_receive(:enqueue).with SubscribeUserJob, @user.id, 'http://www.galactanet.com/feed.xml', nil, true, nil
    Resque.should_receive(:enqueue).with SubscribeUserJob, @user.id, 'https://www.archlinux.org/feeds/news/', folder_linux.id, true, nil
    Resque.should_receive(:enqueue).with SubscribeUserJob, @user.id, 'http://xkcd.com/rss.xml', folder_webcomics.id, true, nil
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'ignores feeds without xmlUrl attribute' do
    filename = File.join __dir__, '..', '..', 'attachments', '1371324422-with-feed-without-attributes.opml'
    file_contents = File.read filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents

    Resque.should_receive(:enqueue).exactly(3).times.with SubscribeUserJob, @user.id, anything, anything, true, nil
    ImportSubscriptionsJob.perform filename, @user.id
  end

  context 'folder structure' do

    it 'creates folders from google-style opml (with folder title)' do
      @user.folders.should be_blank
      ImportSubscriptionsJob.perform @filename, @user.id

      @user.reload
      @user.folders.count.should eq 2

      folder_linux = @user.folders.where(title: 'Linux').first
      folder_linux.should be_present

      folder_webcomics = @user.folders.where(title: 'Webcomics').first
      folder_webcomics.should be_present
    end

    it 'creates folders from TinyTinyRSS-style opml (without folder title)' do
      filename = File.join __dir__, '..', '..', 'attachments', 'TinyTinyRSS.opml'
      file_contents = File.read filename
      Feedbunch::Application.config.uploads_manager.stub read: file_contents

      @user.folders.should be_blank
      ImportSubscriptionsJob.perform @filename, @user.id

      # There are <outline> nodes in the XML which are not actually folders, they should
      # not be imported as folders
      @user.reload
      @user.folders.count.should eq 2

      folder_linux = @user.folders.where(title: 'Retro').first
      folder_linux.should be_present

      folder_webcomics = @user.folders.where(title: 'Webcomics').first
      folder_webcomics.should be_present
    end
  end

  it 'reuses folders already created by the user' do
    folder_linux = FactoryGirl.build :folder, title: 'Linux', user_id: @user.id
    @user.folders << folder_linux
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.folders.count.should eq 2

    @user.folders.should include folder_linux

    folder_webcomics = @user.folders.where(title: 'Webcomics').first
    folder_webcomics.should be_present
  end

  it 'does nothing if the user does not have a opml_import_job_state' do
    @user.opml_import_job_state.destroy
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state NONE' do
    @user.opml_import_job_state.state = OpmlImportJobState::NONE
    @user.opml_import_job_state.save
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state ERROR' do
    @user.opml_import_job_state.state = OpmlImportJobState::ERROR
    @user.opml_import_job_state.save
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state SUCCESS' do
    @user.opml_import_job_state.state = OpmlImportJobState::SUCCESS
    @user.opml_import_job_state.save
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing successfully' do
    Feedbunch::Application.config.uploads_manager.should_receive(:delete).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing with an error' do
    User.any_instance.stub(:opml_import_job_state).and_raise StandardError.new
    Feedbunch::Application.config.uploads_manager.should_receive(:delete).with @user, OPMLImporter::FOLDER, @filename

    expect {ImportSubscriptionsJob.perform @filename, @user.id}.to raise_error StandardError
  end

  context 'email notifications' do

    before :each do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear
    end

    it 'sends an email if it finishes with an error' do
      not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
      file_contents = File.read not_valid_opml_filename
      Feedbunch::Application.config.uploads_manager.stub read: file_contents
      expect {ImportSubscriptionsJob.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      mail_should_be_sent to: @user.email, text: 'There has been an error importing your feed subscriptions into Feedbunch'
    end
  end

end