require 'spec_helper'

describe Api::OpmlExportsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns export process state successfully' do
      get :show, format: :json
      response.status.should eq 200
    end

    it 'assigns the correct opml_export_job_state' do
      get :show, format: :json
      assigns(:opml_export_job_state).should eq @user.opml_export_job_state
    end

  end

  context 'POST create' do

    it 'redirects to main application page if successful' do
      User.any_instance.stub :export_subscriptions
      post :create
      response.should redirect_to read_path
    end

    it 'redirects to main application page if an error happens' do
      User.any_instance.stub(:export_subscriptions).and_raise StandardError.new
      post :create
      response.should redirect_to read_path
    end

    it 'creates a OpmlExportJobState instance with ERROR state if an error happens' do
      User.any_instance.stub(:export_subscriptions).and_raise StandardError.new
      post :create
      @user.reload.opml_export_job_state.state.should eq OpmlExportJobState::ERROR
    end
  end

  context 'PUT update' do

    it 'asigns the correct OpmlExportJobState' do
      put :update, opml_export: {show_alert: 'false'}, format: :json
      assigns(:opml_export_job_state).should eq @user.opml_export_job_state
    end

    it 'returns success' do
      put :update, opml_export: {show_alert: 'false'}, format: :json
      response.should be_success
    end

    it 'returns 500 if there is a problem changing the alert visibility' do
      User.any_instance.stub(:set_opml_export_job_state_visible).and_raise StandardError.new
      put :update, opml_export: {show_alert: 'false'}, format: :json
      response.status.should eq 500
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
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return time_now

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

      Feedbunch::Application.config.uploads_manager.stub(:read).and_return @opml_data
      Feedbunch::Application.config.uploads_manager.stub(:exists?).and_return true
    end

    it 'assigns the correct OPML data' do
      get :download, format: :json
      assigns(:data).should eq @opml_data
    end

    it 'redirects to main application page if an error happens' do
      User.any_instance.stub(:get_opml_export).and_raise OpmlExportDoesNotExistError.new
      get :download, format: :json
      response.should redirect_to read_path
    end

    it 'puts alert in flash if an error happens' do
      User.any_instance.stub(:get_opml_export).and_raise OpmlExportDoesNotExistError.new
      get :download, format: :json
      flash[:alert].should_not be_blank
    end
  end

end