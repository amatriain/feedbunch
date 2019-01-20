require 'rails_helper'

describe Api::FeedsController, type: :controller do

  before :each do
    @user = FactoryBot.create :user

    @feed1 = FactoryBot.create :feed
    @feed2 = FactoryBot.create :feed
    @feed3 = FactoryBot.create :feed

    @entry_1_1 = FactoryBot.build :entry, feed_id: @feed1.id
    @entry_1_2 = FactoryBot.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry_1_1 << @entry_1_2
    @entry2 = FactoryBot.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed3.fetch_url

    @folder1 = FactoryBot.build :folder, user_id: @user.id
    @folder2 = FactoryBot.create :folder
    @user.folders << @folder1
    @folder1.feeds << @feed1 << @feed3

    login_user_for_unit @user
  end

  context 'GET index' do

    context 'all feeds' do

      it 'returns success' do
        get :index, format: :json
        expect(response).to be_successful
      end

      it 'assigns to @feeds only feeds owned by the user' do
        get :index, format: :json
        expect(assigns(:feeds)).to eq [@feed1]
      end

      it 'assigns to @feeds only feeds with unread entries' do
        get :index, format: :json
        expect(assigns(:feeds)).to eq [@feed1]
      end

      it 'assigns to @feeds all feeds if requested' do
        get :index, params: {include_read: 'true'}, format: :json
        expect(assigns(:feeds)).to eq [@feed1, @feed3]
      end
    end

    context 'feeds in a folder' do

      it 'returns success' do
        get :index, params: {folder_id: @folder1.id}, format: :json
        expect(response).to be_successful
      end

      it 'assigns to @folder the correct folder' do
        get :index, params: {folder_id: @folder1.id}, format: :json
        expect(assigns(:folder)).to eq @folder1
      end

      it 'assigns to @feeds only feeds with unread entries' do
        get :index, params: {folder_id: @folder1.id}, format: :json
        expect(assigns(:feeds)).to eq [@feed1]
      end

      it 'assigns to @feeds all feeds if requested' do
        get :index, params: {folder_id: @folder1.id, include_read: 'true'}, format: :json
        feeds = assigns(:feeds)
        expect(feeds.count).to eq 2
        expect(feeds).to include @feed1
        expect(feeds).to include @feed3
      end

      it 'returns 404 if user does not own folder' do
        get :index, params: {folder_id: @folder2.id}, format: :json
        expect(response.status).to eq 404
      end
    end
  end

  context 'GET show' do

    it 'assigns to @feed the correct feed' do
      get :show, params: {id: @feed1.id}, format: :json
      expect(assigns(:feed)).to eq @feed1
    end

    it 'returns a 404 for a feed the user is not suscribed to' do
      get :show, params: {id: @feed2.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      get :show, params: {id: 1234567890}, format: :json
      expect(response.status).to eq 404
    end

  end

  context 'PATCH update' do

    it 'returns a 404 for a feed the user is not suscribed to' do
      patch :update, params: {id: @feed2.id}
      expect(response.status).to eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      patch :update, params: {id: 1234567890}
      expect(response.status).to eq 404
    end

    it 'refreshes feed' do
      expect(FeedRefreshManager).to receive :refresh do |feed, user|
        expect(feed.id).to eq @feed1.id
        expect(user.id).to eq @user.id
      end
      patch :update, params: {id: @feed1.id}
    end
  end

  context 'POST create' do

    it 'assigns to @job_state the new subscribe_job_state' do
      post :create, params: {feed: {url: @feed2.fetch_url}}, format: :json
      expect(response).to  be_successful
      job_state = assigns(:job_state)
      expect(job_state.user_id).to eq @user.id
      expect(job_state.fetch_url).to eq @feed2.fetch_url
      expect(job_state.state).to eq SubscribeJobState::RUNNING
    end
  end

  context 'DELETE remove' do

    it 'returns 200' do
      delete :destroy, params: {id: @feed1.id}, format: :json
      expect(response).to be_successful
    end

    it 'enqueues job to unsubscribe from feed' do
      expect_any_instance_of(User).to receive :enqueue_unsubscribe_job do |user, feed|
        expect(feed.id).to eq @feed1.id
        expect(user.id).to eq @user.id
      end
      delete :destroy, params: {id: @feed1.id}, format: :json
    end

    it 'returns 404 if the feed does not exist' do
      delete :destroy, params: {id: 1234567890}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 if the user is not subscribed to the feed' do
      delete :destroy, params: {id: @feed2.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 500 if there is a problem unsubscribing' do
      allow_any_instance_of(User).to receive(:enqueue_unsubscribe_job).and_raise StandardError.new
      delete :destroy, params: {id: @feed1.id}, format: :json
      expect(response.status).to eq 500
    end
  end
end
