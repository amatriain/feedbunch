require 'rails_helper'

describe ImportSubscriptionsWorker do

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
    ImportSubscriptionsWorker.new.perform @filename, @user.id
    @user.reload
    expect(@user.opml_import_job_state.total_feeds).to eq 4
  end

  it 'sets data import state to ERROR if the file does not exist' do
    expect {ImportSubscriptionsWorker.new.perform 'not.a.real.file', @user.id}.to raise_error OpmlImportError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not well formed XML' do
    not_valid_xml_filename = File.join __dir__, '..', '..', 'attachments', 'not-well-formed-xml.opml'
    file_contents = File.read not_valid_xml_filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
    expect {ImportSubscriptionsWorker.new.perform not_valid_xml_filename, @user.id}.to raise_error Nokogiri::XML::SyntaxError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if the file is not valid OPML' do
    not_valid_opml_filename = File.join __dir__, '..', '..', 'attachments', 'not-valid-opml.opml'
    file_contents = File.read not_valid_opml_filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents
    expect {ImportSubscriptionsWorker.new.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'sets data import state to ERROR if an error is raised' do
    allow(OPMLImporter).to receive(:import).and_raise StandardError.new
    expect {ImportSubscriptionsWorker.new.perform @filename, @user.id}.to raise_error
    @user.reload
    expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
  end

  it 'does nothing if the user does not exist' do
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsWorker.new.perform @filename, 1234567890
  end

  it 'reads uploaded file' do
    expect(Feedbunch::Application.config.uploads_manager).to receive(:read).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'enqueues jobs to subscribe the user to feeds' do
    folder_linux = FactoryGirl.build :folder, user_id: @user.id, title: 'Linux'
    folder_webcomics = FactoryGirl.build :folder, user_id: @user.id, title: 'Webcomics'
    @user.folders << folder_linux << folder_webcomics

    expect(SubscribeUserWorker.jobs.size).to eq 0

    ImportSubscriptionsWorker.new.perform @filename, @user.id

    expect(SubscribeUserWorker.jobs.size).to eq 4

    job1 = SubscribeUserWorker.jobs[0]
    expect(job1['class']).to eq 'SubscribeUserWorker'
    args1 = job1['args']
    # Check the arguments passed to the job
    user_id1 = args1[0]
    expect(user_id1).to eq @user.id
    fetch_url1 = args1[1]
    expect(fetch_url1).to eq 'http://brakemanscanner.org/atom.xml'
    folder_id1 = args1[2]
    expect(folder_id1).to be_nil
    running_opml_import1 = args1[3]
    expect(running_opml_import1).to be true
    job_state_id1 = args1[4]
    expect(job_state_id1).to be_nil

    job2 = SubscribeUserWorker.jobs[1]
    expect(job2['class']).to eq 'SubscribeUserWorker'
    args2 = job2['args']
    # Check the arguments passed to the job
    user_id2 = args2[0]
    expect(user_id2).to eq @user.id
    fetch_url2 = args2[1]
    expect(fetch_url2).to eq 'http://www.galactanet.com/feed.xml'
    folder_id2 = args2[2]
    expect(folder_id2).to be_nil
    running_opml_import2 = args2[3]
    expect(running_opml_import2).to be true
    job_state_id2 = args2[4]
    expect(job_state_id2).to be_nil

    job3 = SubscribeUserWorker.jobs[2]
    expect(job3['class']).to eq 'SubscribeUserWorker'
    args3 = job3['args']
    # Check the arguments passed to the job
    user_id3 = args3[0]
    expect(user_id3).to eq @user.id
    fetch_url3 = args3[1]
    expect(fetch_url3).to eq 'https://www.archlinux.org/feeds/news/'
    folder_id3 = args3[2]
    expect(folder_id3).to eq folder_linux.id
    running_opml_import3 = args3[3]
    expect(running_opml_import3).to be true
    job_state_id3 = args3[4]
    expect(job_state_id3).to be_nil

    job4 = SubscribeUserWorker.jobs[3]
    expect(job4['class']).to eq 'SubscribeUserWorker'
    args4 = job4['args']
    # Check the arguments passed to the job
    user_id4 = args4[0]
    expect(user_id4).to eq @user.id
    fetch_url4 = args4[1]
    expect(fetch_url4).to eq 'http://xkcd.com/rss.xml'
    folder_id4 = args4[2]
    expect(folder_id4).to eq folder_webcomics.id
    running_opml_import4 = args4[3]
    expect(running_opml_import4).to be true
    job_state_id4 = args4[4]
    expect(job_state_id4).to be_nil
  end

  it 'ignores feeds without xmlUrl attribute' do
    filename = File.join __dir__, '..', '..', 'attachments', '1371324422-with-feed-without-attributes.opml'
    file_contents = File.read filename
    allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return file_contents

    expect(SubscribeUserWorker.jobs.size).to eq 0

    ImportSubscriptionsWorker.new.perform filename, @user.id

    expect(SubscribeUserWorker.jobs.size).to eq 3

    job1 = SubscribeUserWorker.jobs[0]
    expect(job1['class']).to eq 'SubscribeUserWorker'
    args1 = job1['args']
    # Check the arguments passed to the job
    user_id1 = args1[0]
    expect(user_id1).to eq @user.id
    running_opml_import1 = args1[3]
    expect(running_opml_import1).to be true
    job_state_id1 = args1[4]
    expect(job_state_id1).to be_nil

    job2 = SubscribeUserWorker.jobs[1]
    expect(job2['class']).to eq 'SubscribeUserWorker'
    args2 = job2['args']
    # Check the arguments passed to the job
    user_id2 = args2[0]
    expect(user_id2).to eq @user.id
    running_opml_import2 = args2[3]
    expect(running_opml_import2).to be true
    job_state_id2 = args2[4]
    expect(job_state_id2).to be_nil

    job3 = SubscribeUserWorker.jobs[2]
    expect(job3['class']).to eq 'SubscribeUserWorker'
    args3 = job3['args']
    # Check the arguments passed to the job
    user_id3 = args3[0]
    expect(user_id3).to eq @user.id
    running_opml_import3 = args3[3]
    expect(running_opml_import3).to be true
    job_state_id3 = args3[4]
    expect(job_state_id3).to be_nil
  end

  context 'folder structure' do

    it 'creates folders from google-style opml (with folder title)' do
      expect(@user.folders).to be_blank
      ImportSubscriptionsWorker.new.perform @filename, @user.id

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
      ImportSubscriptionsWorker.new.perform @filename, @user.id

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
    ImportSubscriptionsWorker.new.perform @filename, @user.id

    @user.reload
    expect(@user.folders.count).to eq 2

    expect(@user.folders).to include folder_linux

    folder_webcomics = @user.folders.where(title: 'Webcomics').first
    expect(folder_webcomics).to be_present
  end

  it 'does nothing if the user does not have a opml_import_job_state' do
    @user.opml_import_job_state.destroy
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state NONE' do
    @user.opml_import_job_state.state = OpmlImportJobState::NONE
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state ERROR' do
    @user.opml_import_job_state.state = OpmlImportJobState::ERROR
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'does nothing if the opml_import_job_state for the user has state SUCCESS' do
    @user.opml_import_job_state.state = OpmlImportJobState::SUCCESS
    @user.opml_import_job_state.save
    expect(Feedbunch::Application.config.uploads_manager).not_to receive :read
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'deletes file after finishing successfully' do
    expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename
    ImportSubscriptionsWorker.new.perform @filename, @user.id
  end

  it 'deletes file after finishing with an error' do
    allow_any_instance_of(User).to receive(:opml_import_job_state).and_raise StandardError.new
    expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).with @user, OPMLImporter::FOLDER, @filename

    expect {ImportSubscriptionsWorker.new.perform @filename, @user.id}.to raise_error StandardError
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
      expect {ImportSubscriptionsWorker.new.perform not_valid_opml_filename, @user.id}.to raise_error OpmlImportError
      mail_should_be_sent to: @user.email, text: 'There has been an error importing your feed subscriptions into Feedbunch'
    end
  end

end