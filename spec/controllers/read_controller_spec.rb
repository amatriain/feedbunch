require 'spec_helper'

describe ReadController do

  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.subscribe @feed1.fetch_url

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder
    @user.folders << @folder1

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns success' do
      get :index
      response.should be_success
    end

    it 'assigns to @feeds only feeds the user is suscribed to' do
      get :index
      assigns(:feeds).should eq [@feed1]
    end

    it 'assigns to @folders only folders that belong to the user' do
      get :index
      assigns(:folders).should eq [@folder1]
    end
  end
end
