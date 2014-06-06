require 'rails_helper'

describe ReadController, type: :controller do

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
  end
end
