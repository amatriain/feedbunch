require 'spec_helper'

describe FeedsController do
  before :each do
    @feed = FactoryGirl.create :feed
  end

  context 'GET index' do
    it 'assigns all feeds to @feeds' do
      get :index
      response.should be_success
      assigns(:feeds).should eq [@feed]
    end
  end
end
