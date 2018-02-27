require 'rails_helper'

describe ImportOpmlWorker do

  before :each do
    # Ensure files are not deleted, we will need them for running tests again!
    allow(File).to receive(:delete).and_return 1

    @user = FactoryBot.create :user
    @opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.opml_import_job_state = @opml_import_job_state

    @filename = '1371324422.opml'
    @filepath = File.join __dir__, '..', '..', 'attachments', @filename
    @file_contents = File.read @filepath

    allow(Feedbunch::Application.config.uploads_manager).to receive :read do |user_id, folder, filename|
      expect(user_id).to eq @user.id
      if filename == @filename
        @file_contents
      else
        nil
      end
    end
    allow(Feedbunch::Application.config.uploads_manager).to receive :save
    allow(Feedbunch::Application.config.uploads_manager).to receive :delete

    allow(ImportSubscriptionsWorker).to receive :perform_async
  end

  context 'validations' do

    it 'sets data import state to ERROR if the file does not exist' do
      expect {ImportOpmlWorker.new.perform 'not.a.real.file', @user.id}.to raise_error OpmlImportError
      @user.reload
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end

    it 'sets data import state to ERROR if the file is not well formed XML' do
      not_valid_xml_filename = File.join __dir__, '..', '..', 'attachments', 'not-well-formed-xml.opml'
      file_contents = File.read not_valid_xml_filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
      # a malformed XML uploaded by the user is an expected and controlled error, no error will be raised to Sidekiq
      expect {ImportOpmlWorker.new.perform not_valid_xml_filename, @user.id}.not_to raise_error
      @user.reload
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end

    it 'sets data import state to ERROR if the file is not valid OPML' do
      not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
      file_contents = File.read not_valid_opml_filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
      expect {ImportOpmlWorker.new.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      @user.reload
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end

    it 'does nothing if the user does not exist' do
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
      ImportOpmlWorker.new.perform @filename, 1234567890
    end

    it 'does nothing if the user does not have a opml_import_job_state' do
      @user.opml_import_job_state.destroy
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state NONE' do
      @user.opml_import_job_state.state = OpmlImportJobState::NONE
      @user.opml_import_job_state.save
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state ERROR' do
      @user.opml_import_job_state.state = OpmlImportJobState::ERROR
      @user.opml_import_job_state.save
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state SUCCESS' do
      @user.opml_import_job_state.state = OpmlImportJobState::SUCCESS
      @user.opml_import_job_state.save
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
      ImportOpmlWorker.new.perform @filename, @user.id
    end
  end

  context 'OPML file management' do

    it 'reads uploaded file' do
      expect(Feedbunch::Application.config.uploads_manager).to receive(:read).with @user.id, OPMLImporter::FOLDER, @filename
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'deletes file after finishing successfully' do
      expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user.id, OPMLImporter::FOLDER, @filename
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'deletes file after finishing with an error' do
      allow_any_instance_of(User).to receive(:opml_import_job_state).and_raise StandardError.new
      expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user.id, OPMLImporter::FOLDER, @filename

      expect {ImportOpmlWorker.new.perform @filename, @user.id}.to raise_error StandardError
    end
  end

  context 'finishes successfully' do

    it 'updates the data import total number of feeds' do
      ImportOpmlWorker.new.perform @filename, @user.id
      @user.reload
      expect(@user.opml_import_job_state.total_feeds).to eq 4
    end

    it 'creates folders in OPML' do
      expect(@user.folders.count).to eq 0

      ImportOpmlWorker.new.perform @filename, @user.id

      expect(@user.reload.folders.count).to eq 2
      folder_title_1 = 'Linux'
      folder_title_2 = 'Webcomics'
      expect(@user.folders.map {|f| f.title}).to contain_exactly folder_title_1, folder_title_2
    end

    it 'enqueues superworker' do
      expect(ImportSubscriptionsWorker).to receive(:perform_async) do |opml_import_job_state_id, urls, folder_ids|
        expect(opml_import_job_state_id).to eq @opml_import_job_state.id
        expect(urls).to eq %w(http://brakemanscanner.org/atom.xml http://www.galactanet.com/feed.xml
                            https://www.archlinux.org/feeds/news/ http://xkcd.com/rss.xml)
        expect(folder_ids.size).to eq 4
        expect(folder_ids[0]).to be nil
        expect(folder_ids[1]).to be nil
        expect(Folder.find(folder_ids[2]).title).to eq 'Linux'
        expect(Folder.find(folder_ids[3]).title).to eq 'Webcomics'
      end

      ImportOpmlWorker.new.perform @filename, @user.id
    end
  end

  context 'finishes with an error' do

    before :each do
      allow(ImportSubscriptionsWorker).to receive(:perform_async).and_raise StandardError.new
    end

    it 'sets data import state to ERROR' do
      expect {ImportOpmlWorker.new.perform @filename, @user.id}.to raise_error StandardError
      @user.reload
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end

    it 'sends notification email' do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear

      not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
      file_contents = File.read not_valid_opml_filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
      expect {ImportOpmlWorker.new.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      mail_should_be_sent 'There has been an error importing your feed subscriptions into', to: @user.email
    end
  end

  context 'folder structure' do

    it 'creates folders from google-style opml (with folder title)' do
      expect(@user.folders).to be_blank
      ImportOpmlWorker.new.perform @filename, @user.id

      @user.reload
      expect(@user.folders.count).to eq 2

      folder_linux = @user.folders.find_by title: 'Linux'
      expect(folder_linux).to be_present

      folder_webcomics = @user.folders.find_by title: 'Webcomics'
      expect(folder_webcomics).to be_present
    end

    it 'creates folders from TinyTinyRSS-style opml (without folder title)' do
      filename = File.join __dir__, '..', '..', 'attachments', 'TinyTinyRSS.opml'
      file_contents = File.read filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents

      expect(@user.folders).to be_blank
      ImportOpmlWorker.new.perform @filename, @user.id

      # There are <outline> nodes in the XML which are not actually folders, they should
      # not be imported as folders
      @user.reload
      expect(@user.folders.count).to eq 2

      folder_linux = @user.folders.find_by title: 'Retro'
      expect(folder_linux).to be_present

      folder_webcomics = @user.folders.find_by title: 'Webcomics'
      expect(folder_webcomics).to be_present
    end

    it 'reuses folders already created by the user' do
      folder_linux = FactoryBot.build :folder, title: 'Linux', user_id: @user.id
      @user.folders << folder_linux
      ImportOpmlWorker.new.perform @filename, @user.id

      @user.reload
      expect(@user.folders.count).to eq 2

      expect(@user.folders).to include folder_linux

      folder_webcomics = @user.folders.find_by title: 'Webcomics'
      expect(folder_webcomics).to be_present
    end
  end

end