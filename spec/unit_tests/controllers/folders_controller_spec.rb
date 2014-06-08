require 'rails_helper'

describe Api::FoldersController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @feed3 = FactoryGirl.create :feed

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @user.subscribe @feed3.fetch_url

    @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1_1 << @entry1_2

    @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
    @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2_1 << @entry2_2

    @entry3_1 = FactoryGirl.build :entry, feed_id: @feed3.id
    @entry3_2 = FactoryGirl.build :entry, feed_id: @feed3.id
    @feed3.entries << @entry3_1 << @entry3_2

    @user.folders << @folder1
    @folder1.feeds << @feed1 << @feed2

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns success' do
      get :index, format: :json
      expect(response).to be_success
    end

    it 'assigns to @folders only folders owned by the user' do
      get :index, format: :json
      expect(assigns(:folders)).to eq [@folder1]
    end
  end

  context 'GET show' do

    it 'assigns the right folder' do
      get :show, id: @folder1.id
      expect(assigns(:folder)).to eq @folder1
    end

    it 'returns a 404 for a folder that does not belong to the user' do
      get :show, id: @folder2.id
      expect(response.status).to eq 404
    end

    it 'returns a 404 for a non-existing folder' do
      get :show, id: 1234567890
      expect(response.status).to eq 404
    end

  end

  context 'PATCH move to folder' do

    it 'returns success' do
      patch :update, id: @folder1.id, folder: {feed_id: @feed3.id}, format: :json
      expect(response).to be_success
    end

    it 'returns 404 for a folder that does not belong to the current user' do
      patch :update, id: @folder2.id, folder: {feed_id: @feed3.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 for a feed the current user is not subscribed to' do
      feed = FactoryGirl.create :feed
      expect(@user.feeds).not_to include feed

      patch :update, id: @folder1.id, folder: {feed_id: feed.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 for non-existing folder' do
      patch :update, id: '1234567890', folder: {feed_id: @feed3.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 for non-existing feed' do
      patch :update, id: @folder1.id, folder: {feed_id: '1234567890'}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 200 if the feed is already in the folder' do
      patch :update, id: @folder1.id, folder: {feed_id: @feed1.id}, format: :json
      expect(response.status).to eq 200
    end

    it 'returns 500 if there is a problem associating the feed with the folder' do
      allow_any_instance_of(User).to receive(:move_feed_to_folder).and_raise StandardError.new
      patch :update, id: @folder1.id, folder: {feed_id: @feed3.id}, format: :json
      expect(response.status).to eq 500
    end
  end

  context 'PATCH remove from folder' do

    it 'returns success' do
      patch :update, id: Folder::NO_FOLDER, folder: {feed_id: @feed1.id}, format: :json
      expect(response).to be_success
    end

    it 'returns 404 if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      patch :update, id: Folder::NO_FOLDER, folder: {feed_id: feed.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 if the feed does not exist' do
      patch :update, id: Folder::NO_FOLDER, folder: {feed_id: 1234567890}, format: :json
      expect(response.status).to eq 404
    end

    it 'deletes the folder if the feed is successfully removed from the folder and there are no more feeds in the folder' do
      # Ensure that @folder1 only has @feed1
      @folder1.feeds.delete @feed2

      patch :update, id: Folder::NO_FOLDER, folder: {feed_id: @feed1.id}, format: :json
      expect(Folder.exists?(@folder1.id)).to be false
    end

    it 'returns 500 if there is a problem removing feed from folder' do
      allow_any_instance_of(User).to receive(:move_feed_to_folder).and_raise StandardError.new
      patch :update, id: Folder::NO_FOLDER, folder: {feed_id: @feed1.id}, format: :json
      expect(response.status).to eq 500
    end
  end

  context 'POST create' do

    it 'returns success if sucessfully created folder' do
      post :create, folder: {title: 'New folder title', feed_id: @feed1.id}, format: :json
      expect(response).to be_success
    end

    it 'returns 304 if user already has a folder with the same title' do
      title = 'Folder title'
      folder = FactoryGirl.build :folder, title: title, user_id: @user.id
      @user.folders << folder

      post :create, folder: {title: title, feed_id: @feed1.id}, format: :json
      expect(response.status).to eq 304
    end

    it 'assigns the new folder to @folder' do
      title = 'New folder title'
      post :create, folder: {title: title, feed_id: @feed1.id}, format: :json
      expect(assigns(:folder).title).to eq title
    end
  end
end