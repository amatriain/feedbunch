require 'spec_helper'

describe FeedsController do
  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1

    @entry1 = FactoryGirl.create :entry
    @entry2 = FactoryGirl.create :entry
    @entry3 = FactoryGirl.create :entry
    @feed1.entries << @entry1 << @entry2

    login_user_for_unit @user

    # Ensure no actual HTTP calls are done
    FeedClient.any_instance.stub :fetch
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
      FeedClient.any_instance.should_not_receive(:fetch).with @feed1.id
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
      FeedClient.any_instance.should_receive(:fetch).with @feed1.id
      get :refresh, id: @feed1.id
    end
  end
end
