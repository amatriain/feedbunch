require 'spec_helper'

describe DataImportsController do

  before :each do
    @user = FactoryGirl.create :user
    @data_import = FactoryGirl.create :data_import_running

    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns import process status successfully' do
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

    it 'creates a DataImport instance with ERROR status if an error happens' do
      User.any_instance.stub(:import_subscriptions).and_raise StandardError.new
      post :create, data_import: {file: 'mock_file'}
      @user.reload.data_import.status.should eq DataImport::ERROR
    end
  end

end