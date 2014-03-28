require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'refresh feed jobs' do

    before :each do
      @refresh_feed_job = @user.create_refresh_job status: RefreshFeedJob::RUNNING
    end

    it 'creates a new data_import with status RUNNING for the user' do
      @user.import_subscriptions @data_file
      @user.data_import.should be_present
      @user.data_import.status.should eq DataImport::RUNNING
    end

    it 'sets data_import status as ERROR if an error is raised' do
      Zip::File.stub(:open).and_raise StandardError.new
      expect{@user.import_subscriptions @data_file}.to raise_error StandardError

      @user.data_import.status.should eq DataImport::ERROR
    end

    context 'unzipped opml file' do

      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', 'attachments', 'subscriptions.xml').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped subscriptions.xml file' do

      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped opml file' do
      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-opml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped xml file' do
      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-xml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end
  end

end
