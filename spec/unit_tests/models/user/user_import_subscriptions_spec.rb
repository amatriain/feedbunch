require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'import subscriptions' do

    before :each do
      @opml_data = File.read File.join(__dir__, '..', '..', '..', 'attachments', 'subscriptions.xml')
      @data_file = File.open File.join(__dir__, '..', '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip')

      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return @opml_data
      allow(Feedbunch::Application.config.uploads_manager).to receive :save
      allow(Feedbunch::Application.config.uploads_manager).to receive :delete

      timestamp = 1371146348
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return Time.zone.at(timestamp)
      @filename = "feedbunch_import_#{timestamp}.opml"
    end

    it 'has a opml_import_job_state with state NONE as soon as the user is created' do
      expect(@user.opml_import_job_state).to be_present
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::NONE
    end

    it 'creates a new opml_import_job_state with state RUNNING for the user' do
      @user.import_subscriptions @data_file
      expect(@user.opml_import_job_state).to be_present
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::RUNNING
    end

    it 'sets opml_import_job_state state as ERROR if an error is raised' do
      allow(Zip::File).to receive(:open).and_raise StandardError.new
      expect{@user.import_subscriptions @data_file}.to raise_error StandardError

      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end

    context 'unzipped opml file' do

      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', '..', 'attachments', 'subscriptions.xml').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        expect(Feedbunch::Application.config.uploads_manager).to receive(:save).with @user, OPMLImporter::FOLDER, @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        expect(ImportSubscriptionsWorker.jobs.size).to eq 0

        @user.import_subscriptions @data_file

        expect(ImportSubscriptionsWorker.jobs.size).to eq 1
        job = ImportSubscriptionsWorker.jobs.first
        expect(job['class']).to eq 'ImportSubscriptionsWorker'
        expect(job['args']).to eq [@filename, @user.id]
      end
    end

    context 'zipped subscriptions.xml file' do

      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', '..', 'attachments', 'feedbunch@gmail.com-takeout.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        expect(Feedbunch::Application.config.uploads_manager).to receive(:save).with @user, OPMLImporter::FOLDER, @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        expect(ImportSubscriptionsWorker.jobs.size).to eq 0

        @user.import_subscriptions @data_file

        expect(ImportSubscriptionsWorker.jobs.size).to eq 1
        job = ImportSubscriptionsWorker.jobs.first
        expect(job['class']).to eq 'ImportSubscriptionsWorker'
        expect(job['args']).to eq [@filename, @user.id]
      end
    end

    context 'zipped opml file' do
      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', '..', 'attachments', 'feedbunch@gmail.com-opml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        expect(Feedbunch::Application.config.uploads_manager).to receive(:save).with @user, OPMLImporter::FOLDER, @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        expect(ImportSubscriptionsWorker.jobs.size).to eq 0

        @user.import_subscriptions @data_file

        expect(ImportSubscriptionsWorker.jobs.size).to eq 1
        job = ImportSubscriptionsWorker.jobs.first
        expect(job['class']).to eq 'ImportSubscriptionsWorker'
        expect(job['args']).to eq [@filename, @user.id]
      end
    end

    context 'zipped xml file' do
      before :each do
        @uploaded_filename = File.join(__dir__, '..', '..', '..', 'attachments', 'feedbunch@gmail.com-xml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        expect(Feedbunch::Application.config.uploads_manager).to receive(:save).with @user, OPMLImporter::FOLDER, @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        expect(ImportSubscriptionsWorker.jobs.size).to eq 0

        @user.import_subscriptions @data_file

        expect(ImportSubscriptionsWorker.jobs.size).to eq 1
        job = ImportSubscriptionsWorker.jobs.first
        expect(job['class']).to eq 'ImportSubscriptionsWorker'
        expect(job['args']).to eq [@filename, @user.id]
      end
    end

    context 'import failures' do

      before :each do
        @job_state = @user.opml_import_job_state
        @import_failure_1 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: @job_state.id
        @import_failure_2 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: @job_state.id
        @job_state.opml_import_failures << @import_failure_1 << @import_failure_2
      end

      it 'destroys old import failures data when enqueuing job to process OPML file' do
        expect(OpmlImportFailure.all.count).to eq 2
        @user.import_subscriptions @data_file
        expect(OpmlImportFailure.all.count).to eq 0
      end

      it 'destroys old import failures data when an error is raised' do
        allow(Zip::File).to receive(:open).and_raise StandardError.new
        expect(OpmlImportFailure.all.count).to eq 2

        expect{@user.import_subscriptions @data_file}.to raise_error StandardError

        expect(OpmlImportFailure.all.count).to eq 0
      end

      it 'does not destroy import failures data for other users' do
        job_state_2 = FactoryGirl.create :opml_import_job_state
        import_failure_3 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: job_state_2.id
        import_failure_4 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: job_state_2.id
        job_state_2.opml_import_failures << import_failure_3 << import_failure_4
        expect(OpmlImportFailure.all.count).to eq 4
        @user.import_subscriptions @data_file
        expect(OpmlImportFailure.all.count).to eq 2
        expect(OpmlImportFailure.all).to contain_exactly import_failure_3, import_failure_4
      end
    end
  end

  context 'change alert visibility' do

    it 'hides alert' do
      expect(@user.opml_import_job_state.show_alert).to be true
      @user.set_opml_import_job_state_visible false
      expect(@user.reload.opml_import_job_state.show_alert).to be false
    end

    it 'shows alert' do
      @user.opml_import_job_state.update show_alert: false
      @user.set_opml_import_job_state_visible true
      expect(@user.reload.opml_import_job_state.show_alert).to be true
    end
  end

end
