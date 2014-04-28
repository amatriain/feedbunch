require 'spec_helper'

describe Api::DataImportsController do

  before :each do
    @user = FactoryGirl.create :user

    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns import process state successfully' do
      get :show, format: :json
      response.status.should eq 200
    end

  end

  context 'POST create' do

    before :each do
      String.any_instance.stub :tempfile
    end

    it 'redirects to main application page if successful' do
      User.any_instance.stub :import_subscriptions
      post :create, data_import: {file: 'mock_file'}
      response.should redirect_to read_path
    end

    it 'redirects to main application page if an error happens' do
      User.any_instance.stub(:import_subscriptions).and_raise StandardError.new
      post :create, data_import: {file: 'mock_file'}
      response.should redirect_to read_path
    end

    it 'creates a OpmlImportJobState instance with ERROR state if an error happens' do
      User.any_instance.stub(:import_subscriptions).and_raise StandardError.new
      post :create, data_import: {file: 'mock_file'}
      @user.reload.data_import.state.should eq OpmlImportJobState::ERROR
    end
  end

  context 'PUT update' do

    it 'asigns the correct OpmlImportJobState' do
      put :update, data_import: {id: @user.data_import.id, show_alert: 'false'}, format: :json
      assigns(:data_import).should eq @user.data_import
    end

    it 'returns success' do
      put :update, data_import: {id: @user.data_import.id, show_alert: 'false'}, format: :json
      response.should be_success
    end

    it 'returns 500 if there is a problem changing the alert visibility' do
      User.any_instance.stub(:set_data_import_visible).and_raise StandardError.new
      put :update, data_import: {id: @user.data_import.id, show_alert: 'false'}, format: :json
      response.status.should eq 500
    end
  end

end