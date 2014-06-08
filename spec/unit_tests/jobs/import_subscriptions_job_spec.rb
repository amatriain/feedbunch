require 'rails_helper'

describe ImportSubscriptionsJob do

  before :each do
    # Ensure files are not deleted, we will need them for running tests again!
    allow(File).to receive(:delete).and_return 1

    @user = FactoryGirl.create :user
    @opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.opml_import_job_state = @opml_import_job_state

    @filename = '1371324422.opml'
    @filepath = File.join __dir__, '..', '..', 'attachments', @filename
    @file_contents = File.read @filepath

    allow(Feedbunch::Application.config.uploads_manager).to receive :read do |user, folder, filename|
      expect(user).to eq @user
      if filename == @filename
        @file_contents
      else
        nil
      end
    end
    allow(Feedbunch::Application.config.uploads_manager).to receive :save
    allow(Feedbunch::Application.config.uploads_manager).to receive :delete
  end

  it 'updates the data import total number of feeds' do
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    expect(@user.opml_import_job_state.total_feeds).to eq 4
  end

  it 'sets data import state to ERROR if the file does not exist' do
    expect {ImportSubscriptionsJob.perform 'not.a.real.file', @user.id}.to raise_error OpmlImportError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not well formed XML' do
    not_valid_xml_filename = File.join __dir__, '..', '..', 'attachments', 'not-well-formed-xml.opml'
    file_contents = File.read not_valid_xml_filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
    expect {ImportSubscriptionsJob.perform not_valid_xml_filename, @user.id}.to raise_error Nokogiri::XML::SyntaxError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not valid OPML' do
    not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
    file_contents = File.read not_valid_opml_filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
    expect {ImportSubscriptionsJob.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if an error is raised' do
    allow(OPMLImporter).to receive(:import).and_raise StandardError.new
    expect {ImportSubscriptionsJob.perform @filename, @user.id}.to raise_error
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'does nothing if the user does not exist' do
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsJob.perform @filename, 1234567890
  end

  it 'reads uploaded file' do
    expect(Feedbunch::Application.config.uploads_manager).to receive(:read).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'enqueues jobs to subscribe the user to feeds' do
    folder_linux = FactoryGirl.build :folder, user_id: @user.id, title: 'Linux'
    folder_webcomics = FactoryGirl.build :folder, user_id: @user.id, title: 'Webcomics'
    @user.folders << folder_linux << folder_webcomics

    expect(Resque).to receive(:enqueue).with SubscribeUserJob, @user.id, 'http://brakemanscanner.org/atom.xml', nil, true, nil
    expect(Resque).to receive(:enqueue).with SubscribeUserJob, @user.id, 'http://www.galactanet.com/feed.xml', nil, true, nil
    expect(Resque).to receive(:enqueue).with SubscribeUserJob, @user.id, 'https://www.archlinux.org/feeds/news/', folder_linux.id, true, nil
    expect(Resque).to receive(:enqueue).with SubscribeUserJob, @user.id, 'http://xkcd.com/rss.xml', folder_webcomics.id, true, nil
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'ignores feeds without xmlUrl attribute' do
    filename = File.join __dir__, '..', '..', 'attachments', '1371324422-with-feed-without-attributes.opml'
    file_contents = File.read filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return: file_contents

    expect(Resque).to receive(:enqueue).exactly(3).times.with SubscribeUserJob, @user.id, anything, anything, true, nil
    ImportSubscriptionsJob.perform filename, @user.id
  end

  context 'folder structure' do

    it 'creates folders from google-style opml (with folder title)' do
      expect(@user.folders).to be_blank
      ImportSubscriptionsJob.perform @filename, @user.id

      @user.reload
      expect(@user.folders.count).to eq 2

      folder_linux = @user.folders.where(title: 'Linux').first
      expect(folder_linux).to be_present

      folder_webcomics = @user.folders.where(title: 'Webcomics').first
      expect(folder_webcomics).to be_present
    end

    it 'creates folders from TinyTinyRSS-style opml (without folder title)' do
      filename = File.join __dir__, '..', '..', 'attachments', 'TinyTinyRSS.opml'
      file_contents = File.read filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents

      expect(@user.folders).to be_blank
      ImportSubscriptionsJob.perform @filename, @user.id

      # There are <outline> nodes in the XML which are not actually folders, they should
      # not be imported as folders
      @user.reload
      expect(@user.folders.count).to eq 2

      folder_linux = @user.folders.where(title: 'Retro').first
      expect(folder_linux).to be_present

      folder_webcomics = @user.folders.where(title: 'Webcomics').first
      expect(folder_webcomics).to be_present
    end
  end

  it 'reuses folders already created by the user' do
    folder_linux = FactoryGirl.build :folder, title: 'Linux', user_id: @user.id
    @user.folders << folder_linux
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    expect(@user.folders.count).to eq 2

    expect(@user.folders).to include folder_linux

    folder_webcomics = @user.folders.where(title: 'Webcomics').first
    expect(folder_webcomics).to be_present
  end

  it 'does nothing if the user does not have a opml_import_job_state' do
    @user.opml_import_job_state.destroy
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state NONE' do
    @user.opml_import_job_state.state = OpmlImportJobState::NONE
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state ERROR' do
    @user.opml_import_job_state.state = OpmlImportJobState::ERROR
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state SUCCESS' do
    @user.opml_import_job_state.state = OpmlImportJobState::SUCCESS
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing successfully' do
    expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing with an error' do
    allow_any_instance_of(User).to receive(:opml_import_job_state).and_raise StandardError.new
    expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename

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
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
      expect {ImportSubscriptionsJob.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      mail_should_be_sent to: @user.email, text: 'There has been an error importing your feed subscriptions into Feedbunch'
    end
  end

end