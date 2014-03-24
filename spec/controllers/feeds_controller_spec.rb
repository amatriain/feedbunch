require 'spec_helper'

describe API::FeedsController do

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

  context 'GET show' do

    it 'assigns to @feed the correct feed' do
      get :show, id: @feed1.id, format: :json
      assigns(:feed).should eq @feed1
    end

    it 'assigns to @entries the entries for a single feed' do
      get :show, id: @feed1.id, format: :json
      assigns(:entries).count.should eq 2
      assigns(:entries).should include @entry_1_1
      assigns(:entries).should include @entry_1_2
    end

    it 'returns a 404 for a feed the user is not suscribed to' do
      get :show, id: @feed2.id, format: :json
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      get :show, id: 1234567890, format: :json
      response.status.should eq 404
    end

    it 'does not fetch new entries in the feed' do
      FeedClient.should_not_receive(:fetch).with @feed1
      get :show, id: @feed1.id, format: :json
    end

    it 'assigns to @entries only unread entries by default' do
      @user.change_entries_state @entry_1_1, 'read'

      get :show, id: @feed1.id, format: :json
      assigns(:entries).count.should eq 1
      assigns(:entries).should include @entry_1_2
    end

    it 'assigns to @entries all entries' do
      @user.change_entries_state @entry_1_1, 'read'

      get :show, id: @feed1.id, include_read: 'true', format: :json
      assigns(:entries).count.should eq 2
      assigns(:entries).should include @entry_1_1
      assigns(:entries).should include @entry_1_2
    end

    context 'pagination' do

      before :each do
        @entries = []
        # Ensure there are exactly 26 unread entries and 4 read entries
        Entry.all.each {|e| e.destroy}
        (0..29).each do |i|
          e = FactoryGirl.build :entry, feed_id: @feed1.id, published: Date.new(2001, 01, 30-i)
          @feed1.entries << e
          @entries << e
        end
        (26..29).each do |i|
          @user.change_entries_state @entries[i], 'read'
        end
      end

      context 'unread entries' do

        it 'returns the first page of entries' do
          get :show, id: @feed1.id, page: 1, format: :json
          assigns(:entries).count.should eq 25
          assigns(:entries).each_with_index do |entry, index|
            entry.should eq @entries[index]
          end
        end

        it 'returns the last page of entries' do
          get :show, id: @feed1.id, page: 2, format: :json
          assigns(:entries).count.should eq 1
          assigns(:entries)[0].should eq @entries[25]
        end

      end

      context 'all entries' do

        it 'returns the first page of entries' do
          get :show, id: @feed1.id, include_read: 'true', page: 1, format: :json
          assigns(:entries).count.should eq 25
          assigns(:entries).each_with_index do |entry, index|
            entry.should eq @entries[index]
          end
        end

        it 'returns the last page of entries' do
          get :show, id: @feed1.id, include_read: 'true', page: 2, format: :json
          assigns(:entries).count.should eq 5
          assigns(:entries).each_with_index do |entry, index|
            entry.should eq @entries[25 + index]
          end
        end

      end

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

    it 'fetches new entries in the feed before returning' do
      FeedClient.should_receive(:fetch).with @feed1, anything
      patch :update, id: @feed1.id
    end
  end

  context 'POST create' do
    it 'returns 304 if the user is already subscribed to the feed' do
      post :create, feed: {url: @feed1.fetch_url}, format: :json
      response.status.should eq 304

      post :create, feed: {url: @feed1.url}, format: :json
      response.status.should eq 304
    end

    it 'assigns to @feed the new subscribed feed' do
      post :create, feed: {url: @feed2.fetch_url}, format: :json
      response.should  be_success
      assigns(:feed).should eq @feed2
    end
  end

  context 'DELETE remove' do

    it 'returns 200' do
      delete :destroy, id: @feed1.id, format: :json
      response.should be_success
    end

    it 'deletes the folder if the feed was in a folder without any other feeds' do
      @folder1.feeds << @feed1

      delete :destroy, id: @feed1.id, format: :json
      Folder.exists?(@folder1.id).should be_false
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
      User.any_instance.stub(:unsubscribe).and_raise StandardError.new
      delete :destroy, id: @feed1.id, format: :json
      response.status.should eq 500
    end
  end
end
