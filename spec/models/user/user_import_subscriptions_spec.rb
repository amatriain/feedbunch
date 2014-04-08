require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'import subscriptions' do

    before :each do
      @opml_data = File.read File.join(__dir__, '..', '..', 'attachments', 'subscriptions.xml')
      @data_file = File.open File.join(__dir__, '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip')

      Feedbunch::Application.config.uploads_manager.stub read: @opml_data
      Feedbunch::Application.config.uploads_manager.stub :save
      Feedbunch::Application.config.uploads_manager.stub :delete

      timestamp = 1371146348
      Time.stub(:now).and_return Time.at(timestamp)
      @filename = "#{timestamp}.opml"
    end

    it 'has a data_import with state NONE as soon as the user is created' do
      @user.data_import.should be_present
      @user.data_import.state.should eq DataImport::NONE
    end

    it 'creates a new data_import with state RUNNING for the user' do
      @user.import_subscriptions @data_file
      @user.data_import.should be_present
      @user.data_import.state.should eq DataImport::RUNNING
    end

    it 'sets data_import state as ERROR if an error is raised' do
      Zip::File.stub(:open).and_raise StandardError.new
      expect{@user.import_subscriptions @data_file}.to raise_error StandardError

      @user.data_import.state.should eq DataImport::ERROR
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

  context 'change alert visibility' do

    it 'hides alert' do
      @user.data_import.show_alert.should be_true
      @user.set_data_import_visible false
      @user.reload.data_import.show_alert.should be_false
    end

    it 'shows alert' do
      @user.data_import.update show_alert: false
      @user.set_data_import_visible true
      @user.reload.data_import.show_alert.should be_true
    end
  end


end
