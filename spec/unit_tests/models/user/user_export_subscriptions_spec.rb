require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'export subscriptions' do

    it 'has a opml_export_job_state with state NONE as soon as the user is created' do
      expect(@user.opml_export_job_state).to be_present
      expect(@user.opml_export_job_state.state).to eq OpmlExportJobState::NONE
    end

    it 'creates a new opml_export_job_state with state RUNNING for the user' do
      @user.export_subscriptions
      expect(@user.opml_export_job_state).to be_present
      expect(@user.opml_export_job_state.state).to eq OpmlExportJobState::RUNNING
    end

    it 'deletes old export job state and OPML files for the user' do
      filename = 'some_file.opml'
      opml_export_job_state = FactoryGirl.build :opml_export_job_state,
                                                user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                filename: filename,
                                                export_date: Time.zone.now
      @user.opml_export_job_state = opml_export_job_state

      allow(Feedbunch::Application.config.uploads_manager).to receive(:exists?).and_return true
      expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).once do |user, folder, file|
        expect(user).to eq @user
        expect(folder).to eq OPMLExporter::FOLDER
        expect(file).to eq filename
      end

      @user.export_subscriptions

      expect(opml_export_job_state.destroyed?).to be true
    end

    it 'sets opml_import_job_state state as ERROR if an error is raised' do
      allow(ExportSubscriptionsWorker).to receive(:perform_async).and_raise StandardError.new
      expect{@user.export_subscriptions}.to raise_error StandardError
      expect(@user.opml_export_job_state.state).to eq OpmlExportJobState::ERROR
    end

  end

  context 'change alert visibility' do

    it 'hides alert' do
      expect(@user.opml_export_job_state.show_alert).to be true
      @user.set_opml_export_job_state_visible false
      expect(@user.reload.opml_export_job_state.show_alert).to be false
    end

    it 'shows alert' do
      @user.opml_export_job_state.update show_alert: false
      @user.set_opml_export_job_state_visible true
      expect(@user.reload.opml_export_job_state.show_alert).to be true
    end
  end

  context 'return export file' do

    before :each do
      @filename = OPMLExporter::FILENAME
      @opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                 state: OpmlExportJobState::SUCCESS,
                                                 filename: @filename,
                                                 export_date: Time.zone.now
      @user.opml_export_job_state = @opml_export_job_state

      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed
      @feed4 = FactoryGirl.create :feed

      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url
      @user.subscribe @feed4.fetch_url

      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
      @folder.feeds << @feed3 << @feed4

      time_now = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return time_now

      @opml_data = <<OPML_DOCUMENT
<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0">
  <head>
    <title>RSS subscriptions exported by Feedbunch (feedbunch.com)</title>
    <ownerName>#{@user.name}</ownerName>
    <ownerEmail>#{@user.email}</ownerEmail>
    <dateCreated>#{time_now.rfc822}</dateCreated>
  </head>
  <body>
    <outline type="rss" title="#{@feed1.title}" text="#{@feed1.title}" xmlUrl="#{@feed1.fetch_url}" htmlUrl="#{@feed1.url}"/>
    <outline type="rss" title="#{@feed2.title}" text="#{@feed2.title}" xmlUrl="#{@feed2.fetch_url}" htmlUrl="#{@feed2.url}"/>
    <outline title="#{@folder.title}" text="#{@folder.title}">
      <outline type="rss" title="#{@feed3.title}" text="#{@feed3.title}" xmlUrl="#{@feed3.fetch_url}" htmlUrl="#{@feed3.url}"/>
      <outline type="rss" title="#{@feed4.title}" text="#{@feed4.title}" xmlUrl="#{@feed4.fetch_url}" htmlUrl="#{@feed4.url}"/>
    </outline>
  </body>
</opml>
OPML_DOCUMENT

      allow(Feedbunch::Application.config.uploads_manager).to receive(:read).and_return @opml_data
      allow(Feedbunch::Application.config.uploads_manager).to receive(:exists?).and_return true
    end

    it 'returns the correct OPML data' do
      opml = @user.get_opml_export
      expect(opml).to eq @opml_data
    end

    it 'raises an error if the user has not ran an OPML export' do
      @user.opml_export_job_state.update state: OpmlExportJobState::NONE
      expect {@user.get_opml_export}.to raise_error OpmlExportDoesNotExistError
    end

    it 'raises an error if the user has ran an OPML export that finished with ERROR state' do
      @user.opml_export_job_state.update state: OpmlExportJobState::ERROR
      expect {@user.get_opml_export}.to raise_error OpmlExportDoesNotExistError
    end

    it 'raises an error if the user has an OPML export still running' do
      @user.opml_export_job_state.update state: OpmlExportJobState::RUNNING
      expect {@user.get_opml_export}.to raise_error OpmlExportDoesNotExistError
    end

    it 'raises an error if the file does not exist' do
      allow(Feedbunch::Application.config.uploads_manager).to receive(:exists?).and_return false
      expect {@user.get_opml_export}.to raise_error OpmlExportDoesNotExistError
    end
  end

end
