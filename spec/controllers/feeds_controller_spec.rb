require 'spec_helper'

describe FeedsController do
  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder
    @user.folders << @folder1

    login_user_for_unit @user

    # Ensure no actual HTTP calls are done
    FeedClient.stub :fetch
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

  context 'GET show' do
    it 'assigns to @feed the correct object' do
      get :show, id: @feed1.id
      assigns(:feed).should eq @feed1
    end

    it 'returns nothing for a feed the user is not suscribed to' do
      expect { get :show, id: @feed2.id, format: :json }.to raise_error ActiveRecord::RecordNotFound
      assigns(:feed).should be_blank
    end

    it 'does not fetch new entries in the feed' do
      FeedClient.should_not_receive(:fetch).with @feed1.id
      get :show, id: @feed1.id
    end
  end

  context 'GET refresh' do
    it 'assigns to @feed the correct object' do
      get :refresh, id: @feed1.id
      assigns(:feed).should eq @feed1
    end

    it 'returns nothing for a feed the user is not suscribed to' do
      expect { get :refresh, id: @feed2.id, format: :json }.to raise_error ActiveRecord::RecordNotFound
      assigns(:feed).should be_blank
    end

    it 'fetches new entries in the feed before returning' do
      FeedClient.should_receive(:fetch).with @feed1.id
      get :refresh, id: @feed1.id
    end
  end

  context 'POST create' do
    it 'returns 304 if the user is already subscribed to the feed' do
      post :create, format: :json, subscription: {rss: @feed1.fetch_url}
      response.status.should eq 304

      post :create, subscription: {rss: @feed1.url}
      response.status.should eq 304
    end
  end
end
