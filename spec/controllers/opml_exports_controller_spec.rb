require 'spec_helper'

describe Api::OpmlExportsController do

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

end