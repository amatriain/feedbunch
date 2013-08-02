require 'spec_helper'

describe EntriesController do

  before :each do
    @feed = FactoryGirl.create :feed
    @user = FactoryGirl.create :user
    @user.subscribe @feed.fetch_url
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    login_user_for_unit @user
  end

  context 'PUT update' do
    it 'returns success' do
      put :update, entry_ids: [@entry.id], state: 'read', format: :json
      response.should be_success
    end

    it 'returns 404 if the folder does not exist' do
      put :update, entry_ids: [1234567890], state: 'read', format: :json
      response.status.should eq 404
    end

    it 'returns 404 if the user is not subscribed to the entries feed' do
      entry2 = FactoryGirl.create :entry
      put :update, entry_ids: [entry2.id], state: 'read', format: :json
      response.status.should eq 404
    end

    it 'returns 500 if there is a problem changing the entry state' do
      User.any_instance.stub(:change_entry_state).and_raise StandardError.new
      put :update, entry_ids: [@entry.id], state: 'read', format: :json
      response.status.should eq 500
    end

    it 'assigns the correct feed to @feeds' do
      put :update, entry_ids: [@entry.id], state: 'read', format: :json
      assigns(:feeds).should eq [@feed]
    end

    it 'assigns the correct folder to @folders' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      put :update, entry_ids: [@entry.id], state: 'read', format: :json
      assigns(:folders).should eq [folder]
    end
  end
end