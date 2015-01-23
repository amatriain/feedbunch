require 'rails_helper'

describe NotifyImportFinishedWorker do

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
      expect {ImportOpmlWorker.new.perform not_valid_xml_filename, @user.id}.to raise_error Nokogiri::XML::SyntaxError
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
      expect(Feedbunch::Application.config.uploads_manager).to receive(:read).with @user, OPMLImporter::FOLDER, @filename
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'deletes file after finishing successfully' do
      expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename
      ImportOpmlWorker.new.perform @filename, @user.id
    end

    it 'deletes file after finishing with an error' do
      allow_any_instance_of(User).to receive(:opml_import_job_state).and_raise StandardError.new
      expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename

      expect {ImportOpmlWorker.new.perform @filename, @user.id}.to raise_error StandardError
    end
  end

  context 'finishes successfully' do

    before :each do
      allow_any_instance_of(User).to receive :subscribe do |user, fetch_url|
        expect(user.id).to eq @user.id
        feed = FactoryGirl.create :feed, fetch_url: fetch_url
        subscription = FactoryGirl.create :feed_subscription, user_id: user.id, feed_id: feed.id
        feed
      end
    end

    it 'sets data import state to SUCCESS after all feeds have been processed' do
      ImportOpmlWorker.new.perform @filename, @user.id
      @user.reload
      expect(@user.opml_import_job_state.processed_feeds).to eq 4
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::SUCCESS
    end

    it 'updates the data import total number of feeds' do
      ImportOpmlWorker.new.perform @filename, @user.id
      @user.reload
      expect(@user.opml_import_job_state.total_feeds).to eq 4
    end

    it 'updates the data import number of processed feeds' do
      ImportOpmlWorker.new.perform @filename, @user.id
      @user.reload
      expect(@user.opml_import_job_state.processed_feeds).to eq 4
    end

    it 'subscribes user to feeds in OPML' do
      expect(@user.feeds.count).to eq 0

      ImportOpmlWorker.new.perform @filename, @user.id

      expect(@user.reload.feeds.count).to eq 4
      feed_url_1 = 'http://brakemanscanner.org/atom.xml'
      feed_url_2 = 'http://www.galactanet.com/feed.xml'
      feed_url_3 = 'https://www.archlinux.org/feeds/news/'
      feed_url_4 = 'http://xkcd.com/rss.xml'
      expect(@user.feeds.map {|f| f.fetch_url}).to contain_exactly feed_url_1, feed_url_2, feed_url_3, feed_url_4
    end

    it 'creates folders in OPML' do
      expect(@user.folders.count).to eq 0

      ImportOpmlWorker.new.perform @filename, @user.id

      expect(@user.reload.folders.count).to eq 2
      folder_title_1 = 'Linux'
      folder_title_2 = 'Webcomics'
      expect(@user.folders.map {|f| f.title}).to contain_exactly folder_title_1, folder_title_2

      folder_linux = @user.folders.find_by_title folder_title_1
      expect(folder_linux.feeds.count).to eq 1
      expect(folder_linux.feeds.first.fetch_url).to eq 'https://www.archlinux.org/feeds/news/'

      folder_webcomics = @user.folders.find_by_title folder_title_2
      expect(folder_webcomics.feeds.count).to eq 1
      expect(folder_webcomics.feeds.first.fetch_url).to eq 'http://xkcd.com/rss.xml'
    end
  end

  context 'finishes with an error' do

    before :each do
      allow(OPMLImporter).to receive(:import).and_raise StandardError.new
    end

    it 'sets data import state to ERROR if an error is raised' do
      expect {ImportOpmlWorker.new.perform @filename, @user.id}.to raise_error
      @user.reload
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
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
      folder_linux = FactoryGirl.build :folder, title: 'Linux', user_id: @user.id
      @user.folders << folder_linux
      ImportOpmlWorker.new.perform @filename, @user.id

      @user.reload
      expect(@user.folders.count).to eq 2

      expect(@user.folders).to include folder_linux

      folder_webcomics = @user.folders.find_by title: 'Webcomics'
      expect(folder_webcomics).to be_present
    end
  end

  context 'failed URLs during import' do

    before :each do
      allow_any_instance_of(User).to receive :subscribe do |user, fetch_url|
        expect(user.id).to eq @user.id
        if fetch_url == 'http://xkcd.com/rss.xml' || fetch_url == 'http://brakemanscanner.org/atom.xml'
          raise RestClient::Exception.new
        end
        feed = FactoryGirl.create :feed, fetch_url: fetch_url
        subscription = FactoryGirl.create :feed_subscription, user_id: user.id, feed_id: feed.id
        feed
      end
    end

    it 'creates OpmlImportFailure instances for failed imports' do
      expect(OpmlImportFailure.all.count).to eq 0
      ImportOpmlWorker.new.perform @filename, @user.id
      expect(OpmlImportFailure.all.count).to eq 2
      expect(OpmlImportFailure.all.map{|f| f.url}).to contain_exactly 'http://xkcd.com/rss.xml',
                                                                  'http://brakemanscanner.org/atom.xml'
    end
  end

  context 'email notifications' do

    before :each do
      # Remove emails stil in the mail queue
      ActionMailer::Base.deliveries.clear
    end

    it 'sends an email if it finishes successfully' do
      ImportOpmlWorker.new.perform @filename, @user.id
      mail_should_be_sent 'Your feed subscriptions have been imported into', to: @user.email
    end

    it 'sends an email with failed feeds if it finishes successfully' do
      allow_any_instance_of(User).to receive :subscribe do |user, fetch_url|
        expect(user.id).to eq @user.id
        raise RestClient::Exception.new if fetch_url == 'http://xkcd.com/rss.xml'
        feed = FactoryGirl.create :feed, fetch_url: fetch_url
        subscription = FactoryGirl.create :feed_subscription, user_id: user.id, feed_id: feed.id
        feed
      end

      ImportOpmlWorker.new.perform @filename, @user.id

      mail_should_be_sent 'We haven&#39;t been able to subscribe you to the following feeds',
                          'http://xkcd.com/rss.xml',
                          to: @user.email
    end

    it 'sends an email if it finishes with an error' do
      not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
      file_contents = File.read not_valid_opml_filename
      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
      expect {ImportOpmlWorker.new.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      mail_should_be_sent 'There has been an error importing your feed subscriptions into', to: @user.email
    end
  end

end