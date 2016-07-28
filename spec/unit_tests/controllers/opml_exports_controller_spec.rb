require 'rails_helper'

describe Api::OpmlExportsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns export process state successfully' do
      get :show, format: :json
      expect(response.status).to eq 200
    end

    it 'assigns the correct opml_export_job_state' do
      get :show, format: :json
      expect(assigns(:opml_export_job_state)).to eq @user.opml_export_job_state
    end

  end

  context 'POST create' do

    it 'redirects to main application page if successful' do
      allow_any_instance_of(User).to receive :export_subscriptions
      post :create
      expect(response).to redirect_to read_path
    end

    it 'redirects to main application page if an error happens' do
      allow_any_instance_of(User).to receive(:export_subscriptions).and_raise StandardError.new
      post :create
      expect(response).to redirect_to read_path
    end

    it 'creates a OpmlExportJobState instance with ERROR state if an error happens' do
      allow_any_instance_of(User).to receive(:export_subscriptions).and_raise StandardError.new
      post :create
      expect(@user.reload.opml_export_job_state.state).to eq OpmlExportJobState::ERROR
    end
  end

  context 'PUT update' do

    it 'asigns the correct OpmlExportJobState' do
      put :update, params: {opml_export: {show_alert: 'false'}}, format: :json
      expect(assigns(:opml_export_job_state)).to eq @user.opml_export_job_state
    end

    it 'returns success' do
      put :update, params: {opml_export: {show_alert: 'false'}}, format: :json
      expect(response).to be_success
    end

    it 'returns 500 if there is a problem changing the alert visibility' do
      allow_any_instance_of(User).to receive(:set_opml_export_job_state_visible).and_raise StandardError.new
      put :update, params: {opml_export: {show_alert: 'false'}}, format: :json
      expect(response.status).to eq 500
    end
  end

  context 'GET download' do

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

    it 'assigns the correct OPML data' do
      get :download, format: :json
      expect(assigns(:data)).to eq @opml_data
    end

    it 'redirects to main application page if an error happens' do
      allow_any_instance_of(User).to receive(:get_opml_export).and_raise OpmlExportDoesNotExistError.new
      get :download, format: :json
      expect(response).to redirect_to read_path
    end

    it 'puts alert in flash if an error happens' do
      allow_any_instance_of(User).to receive(:get_opml_export).and_raise OpmlExportDoesNotExistError.new
      get :download, format: :json
      expect(flash[:alert]).not_to be_blank
    end
  end

end