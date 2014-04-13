require 'spec_helper'

describe Api::FeedsController do

  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @feed3 = FactoryGirl.create :feed

    @entry_1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry_1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry_1_1 << @entry_1_2
    @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed3.fetch_url

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder
    @user.folders << @folder1

    login_user_for_unit @user
  end

  context 'GET index' do

    context 'all feeds' do

      it 'returns success' do
        get :index, format: :json
        response.should be_success
      end

      it 'assigns to @feeds only feeds owned by the user' do
        get :index, format: :json
        assigns(:feeds).should eq [@feed1]
      end

      it 'assigns to @feeds only feeds with unread entries' do
        get :index, format: :json
        assigns(:feeds).should eq [@feed1]
      end

      it 'assigns to @feeds all feeds if requested' do
        get :index, include_read: 'true', format: :json
        assigns(:feeds).should eq [@feed1, @feed3]
      end
    end

    context 'feeds in a folder' do

      it 'returns success' do
        get :index, folder_id: @folder1.id, format: :json
        response.should be_success
      end

      it 'assigns to @folder the correct folder' do
        get :index, folder_id: @folder1.id, format: :json
        assigns(:folder).should eq @folder1
      end

      it 'assigns to @feeds only feeds with unread entries' do
        get :index, folder_id: @folder1.id, format: :json
        assigns(:feeds).should eq [@feed1]
      end

      it 'assigns to @feeds all feeds if requested' do
        get :index, folder_id: @folder1.id, include_read: 'true', format: :json
        feeds = assigns(:feeds)
        feeds.count.should eq 2
        feeds.should include @feed1
        feeds.should include @feed3
      end

      it 'returns 404 if user does not own folder'
    end
  end

  context 'GET show' do

    it 'assigns to @feed the correct feed' do
      get :show, id: @feed1.id, format: :json
      assigns(:feed).should eq @feed1
    end

    it 'returns a 404 for a feed the user is not suscribed to' do
      get :show, id: @feed2.id, format: :json
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      get :show, id: 1234567890, format: :json
      response.status.should eq 404
    end

  end

  context 'PATCH update' do

    it 'returns a 404 for a feed the user is not suscribed to' do
      patch :update, id: @feed2.id
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      patch :update, id: 1234567890
      response.status.should eq 404
    end

    it 'refreshes feed' do
      FeedRefreshManager.should_receive :refresh do |feed, user|
        feed.id.should eq @feed1.id
        user.id.should eq @user.id
      end
      patch :update, id: @feed1.id
    end
  end

  context 'POST create' do

    it 'assigns to @job_state the new subscribe_job_state' do
      post :create, feed: {url: @feed2.fetch_url}, format: :json
      response.should  be_success
      job_state = assigns(:job_state)
      job_state.user_id.should eq @user.id
      job_state.fetch_url.should eq @feed2.fetch_url
      job_state.state.should eq SubscribeJobState::RUNNING
    end
  end

  context 'DELETE remove' do

    it 'returns 200' do
      delete :destroy, id: @feed1.id, format: :json
      response.should be_success
    end

    it 'enqueues job to unsubscribe from feed' do
      User.any_instance.should_receive :enqueue_unsubscribe_job do |feed|
        feed.id.should eq @feed1.id
        id.should eq @user.id
      end
      delete :destroy, id: @feed1.id, format: :json
    end

    it 'returns 404 if the feed does not exist' do
      delete :destroy, id: 1234567890, format: :json
      response.status.should eq 404
    end

    it 'returns 404 if the user is not subscribed to the feed' do
      delete :destroy, id: @feed2.id, format: :json
      response.status.should eq 404
    end

    it 'returns 500 if there is a problem unsubscribing' do
      User.any_instance.stub(:enqueue_unsubscribe_job).and_raise StandardError.new
      delete :destroy, id: @feed1.id, format: :json
      response.status.should eq 500
    end
  end
end
