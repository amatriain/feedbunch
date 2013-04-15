require 'spec_helper'

describe FeedsController do
  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1
  end

  context 'GET index' do
    it 'assigns to @feeds only feeds the user is suscribed to' do
      get :index
      response.should be_success
      assigns(:feeds).should eq [@feed1]
    end
  end
end
