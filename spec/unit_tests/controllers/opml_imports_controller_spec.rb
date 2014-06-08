require 'rails_helper'

describe Api::OpmlImportsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user

    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns import process state successfully' do
      get :show, format: :json
      expect(response.status).to eq 200
    end

    it 'assigns the correct opml_import_job_state' do
      get :show, format: :json
      expect(assigns(:opml_import_job_state)).to eq @user.opml_import_job_state
    end

  end

  context 'POST create' do

    before :each do
      allow_any_instance_of(String).to receive :tempfile
    end

    it 'redirects to main application page if successful' do
      allow_any_instance_of(User).to receive :import_subscriptions
      post :create, opml_import: {file: 'mock_file'}
      expect(response).to redirect_to read_path
    end

    it 'redirects to main application page if an error happens' do
      allow_any_instance_of(User).to receive(:import_subscriptions).and_raise StandardError.new
      post :create, opml_import: {file: 'mock_file'}
      expect(response).to redirect_to read_path
    end

    it 'creates a OpmlImportJobState instance with ERROR state if an error happens' do
      allow_any_instance_of(User).to receive(:import_subscriptions).and_raise StandardError.new
      post :create, opml_import: {file: 'mock_file'}
      expect(@user.reload.opml_import_job_state.state).to eq OpmlImportJobState::ERROR
    end
  end

  context 'PUT update' do

    it 'asigns the correct OpmlImportJobState' do
      put :update, opml_import: {show_alert: 'false'}, format: :json
      expect(assigns(:opml_import_job_state)).to eq @user.opml_import_job_state
    end

    it 'returns success' do
      put :update, opml_import: {show_alert: 'false'}, format: :json
      expect(response).to be_success
    end

    it 'returns 500 if there is a problem changing the alert visibility' do
      allow_any_instance_of(User).to receive(:set_opml_import_job_state_visible).and_raise StandardError.new
      put :update, opml_import: {show_alert: 'false'}, format: :json
      expect(response.status).to eq 500
    end
  end

end