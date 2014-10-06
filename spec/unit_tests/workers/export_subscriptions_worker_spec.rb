require 'rails_helper'

describe ExportSubscriptionsWorker do

  before :each do
    @user = FactoryGirl.create :user
    @opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                               state: OpmlExportJobState::RUNNING
    @user.opml_export_job_state = @opml_export_job_state

    @feed1 = FactoryGirl.create :feed, title: 'feed_1'
    @feed2 = FactoryGirl.create :feed, title: 'feed_2'
    @feed3 = FactoryGirl.create :feed, title: 'feed_3'
    @feed4 = FactoryGirl.create :feed, title: 'feed_4'

    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry3 = FactoryGirl.build :entry, feed_id: @feed3.id
    @feed1.entries << @entry1
    @feed3.entries << @entry3

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @user.subscribe @feed3.fetch_url
    @user.subscribe @feed4.fetch_url

    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed3 << @feed4

    time_now = Time.zone.parse '2000-01-01'
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return time_now

    @opml = <<OPML_DOCUMENT
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

    allow(Feedbunch::Application.config.uploads_manager).to receive :save
    allow(Feedbunch::Application.config.uploads_manager).to receive :delete
  end

  after :each do
    uploaded_files = File.join Rails.root, 'uploads', '*.opml'
    Dir.glob(uploaded_files).each {|f| File.delete f}
  end

  context 'validations' do

    it 'does nothing if user does not exist' do
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :save
      ExportSubscriptionsWorker.new.perform 1234567890
    end

    it 'does nothing if the user does not have a opml_export_job_state' do
      @user.opml_export_job_state.destroy
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :save
      ExportSubscriptionsWorker.new.perform @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state NONE' do
      @user.opml_export_job_state.update state: OpmlExportJobState::NONE
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :save
      ExportSubscriptionsWorker.new.perform @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state ERROR' do
      @user.opml_export_job_state.update state: OpmlExportJobState::ERROR
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :save
      ExportSubscriptionsWorker.new.perform @user.id
    end

    it 'does nothing if the opml_import_job_state for the user has state SUCCESS' do
      @user.opml_export_job_state.update state: OpmlExportJobState::SUCCESS,
                                         filename: 'some_filename.opml',
                                         export_date: Time.zone.now
      expect(Feedbunch::Application.config.uploads_manager).not_to receive :save
      ExportSubscriptionsWorker.new.perform @user.id
    end
  end

  it 'uploads correct OPML file' do
    expect(Feedbunch::Application.config.uploads_manager).to receive(:save) do |user, folder, filename, content|
      expect(user).to eq @user
      expect(folder).to eq OPMLExporter::FOLDER
      expect(filename).to eq OPMLExporter::FILENAME
      expect(content).to eq @opml
    end
    ExportSubscriptionsWorker.new.perform @user.id
  end

  it 'sets data export state to ERROR if there is a problem doing the export' do
    allow(OPMLExporter).to receive(:export).and_raise StandardError.new
    expect {ExportSubscriptionsWorker.new.perform @user.id}.to raise_error StandardError
    expect(@user.reload.opml_export_job_state.state).to eq OpmlExportJobState::ERROR
  end

  it 'sets data export state to SUCCESS if the export finishes successfully' do
    ExportSubscriptionsWorker.new.perform @user.id
    expect(@user.reload.opml_export_job_state.state).to eq OpmlExportJobState::SUCCESS
  end

  context 'email notifications' do

    it 'sends notification if finished successfully' do
      ExportSubscriptionsWorker.new.perform @user.id
      mail_should_be_sent to: @user.email, text: 'Your feed subscriptions have been exported by Feedbunch'
    end

    it 'sends notification if finished with an error' do
      allow(OPMLExporter).to receive(:export).and_raise StandardError.new
      expect {ExportSubscriptionsWorker.new.perform @user.id}.to raise_error
      mail_should_be_sent to: @user.email, text: 'There has been an error exporting your feed subscriptions from Feedbunch'
    end
  end

end