require 'spec_helper'

describe FoldersController do

  before :each do
    @user = FactoryGirl.create :user
    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @feed3 = FactoryGirl.create :feed

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
    @user.feeds << @feed1 << @feed2 << @feed3

    login_user_for_unit @user

    # Ensure no actual HTTP calls are done
    FeedClient.stub :fetch
    RestClient.stub :get
  end

  context 'GET show' do

    it 'assigns to @entries the entries for all feeds in a single folder' do
      get :show, id: @folder1.id
      assigns(:entries).count.should eq 4
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2
    end

    it 'assigns to @entries the entries for all subscribed feeds' do
      get :show, id: 'all'
      assigns(:entries).count.should eq 6
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2
      assigns(:entries).should include @entry3_1
      assigns(:entries).should include @entry3_2
    end

    it 'returns a 404 for a folder that does not belong to the user' do
      get :show, id: @folder2.id
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing folder' do
      get :show, id: 1234567890
      response.status.should eq 404
    end

    it 'does not fetch new entries for any feed' do
      FeedClient.should_not_receive(:fetch).with @feed1.id
      get :show, id: @folder1.id
    end

  end

  context 'GET refresh' do

    it 'assigns to @entries the list of entries of a folder' do
      entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id
      entry2_3 = FactoryGirl.build :entry, feed_id: @feed2.id

      # At first the folder has the initial entries
      get :refresh, id: @folder1.id
      assigns(:entries).count.should eq 4
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2

      FeedClient.stub :fetch do
        @feed1.entries << entry1_3
        @feed2.entries << entry2_3
      end

      # New entries should appear now
      get :refresh, id: @folder1.id
      assigns(:entries).count.should eq 6
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include entry1_3
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2
      assigns(:entries).should include entry2_3
    end

    it 'assigns to @entries the list of entries of all feeds' do
      entry1_3 = FactoryGirl.build :entry, feed_id: @feed1.id
      entry2_3 = FactoryGirl.build :entry, feed_id: @feed2.id
      entry3_3 = FactoryGirl.build :entry, feed_id: @feed3.id

      # At first the folder has the initial entries
      get :refresh, id: 'all'
      assigns(:entries).count.should eq 6
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2
      assigns(:entries).should include @entry3_1
      assigns(:entries).should include @entry3_2

      @feed1.entries << entry1_3
      @feed2.entries << entry2_3
      @feed3.entries << entry3_3

      # New entries should appear now
      get :refresh, id: 'all'
      #assigns(:entries).count.should eq 9
      assigns(:entries).should include @entry1_1
      assigns(:entries).should include @entry1_2
      assigns(:entries).should include entry1_3
      assigns(:entries).should include @entry2_1
      assigns(:entries).should include @entry2_2
      assigns(:entries).should include entry2_3
      assigns(:entries).should include @entry3_1
      assigns(:entries).should include @entry3_2
      assigns(:entries).should include entry3_3
    end

    it 'returns a 404 for a folder that does not belong to the user' do
      get :refresh, id: @folder2.id
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing folder' do
      get :refresh, id: 1234567890
      response.status.should eq 404
    end

    it 'fetches new entries in the folder before returning' do
      FeedClient.should_receive(:fetch).with @feed1.id
      FeedClient.should_receive(:fetch).with @feed2.id
      get :refresh, id: @folder1.id
    end

  end

  context 'PUT update' do

    it 'returns success' do
      put :update, id: @folder1.id, feed_id: @feed3.id
      response.should be_success
    end

    it 'returns 404 for a folder that does not belong to the current user' do
      put :update, id: @folder2.id, feed_id: @feed3.id
      response.status.should eq 404
    end

    it 'returns 404 for a feed the current user is not subscribed to' do
      feed = FactoryGirl.create :feed
      @user.feeds.should_not include feed

      put :update, id: @folder1.id, feed_id: feed.id
      response.status.should eq 404
    end

    it 'returns 404 for non-existing folder' do
      put :update, id: '1234567890', feed_id: @feed3.id
      response.status.should eq 404
    end

    it 'returns 404 for non-existing feed' do
      put :update, id: @folder1.id, feed_id: '1234567890'
      response.status.should eq 404
    end

    it 'returns 304 if the feed is already in the folder' do
      put :update, id: @folder1.id, feed_id: @feed1.id
      response.status.should eq 304
    end

    it 'returns 500 if there is a problem associating the feed with the folder' do
      Folder.stub(:add_feed).and_raise StandardError.new
      put :update, id: @folder1.id, feed_id: @feed3.id
      response.status.should eq 500
    end
  end

  context 'DELETE destroy' do

    it 'returns 404 if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      delete :remove, feed_id: feed.id
      response.status.should eq 404
    end

    it 'returns 404 if the feed does not exist' do
      delete :remove, feed_id: 1234567890
      response.status.should eq 404
    end

    it 'returns 304 if the feed is not in any folder' do
      delete :remove, feed_id: @feed3.id
      response.status.should eq 304
    end

    it 'returns 204 if the feed is successfully removed from the folder and there are more feeds in the folder' do
      delete :remove, feed_id: @feed1.id
      response.status.should eq 204
    end

    it 'returns 205 if the feed is successfully removed from the folder and there are no more feeds in the folder' do
      # Ensure that @folder1 only has @feed1
      @folder1.feeds.delete @feed2

      delete :remove, feed_id: @feed1.id
      response.status.should eq 205
    end

    it 'deletes the folder if the feed is successfully removed from the folder and there are no more feeds in the folder' do
      # Ensure that @folder1 only has @feed1
      @folder1.feeds.delete @feed2

      delete :remove, feed_id: @feed1.id
      Folder.exists?(@folder1.id).should be_false
    end

    it 'returns 500 if there is a problem removing feed from folder' do
      Folder.stub(:remove_feed).and_raise StandardError.new
      delete :remove, feed_id: @feed1.id
      response.status.should eq 500
    end
  end

  context 'POST create' do

    it 'returns success if sucessfully created folder' do
      post :create, new_folder: {title: 'New folder title', feed_id: @feed1.id}, format: :json
      response.should be_success
    end

    it 'returns 304 if user already has a folder with the same title' do
      title = 'Folder title'
      folder = FactoryGirl.build :folder, title: title, user_id: @user.id
      @user.folders << folder

      post :create, new_folder: {title: title, feed_id: @feed1.id}
      response.status.should eq 304
    end
  end
end