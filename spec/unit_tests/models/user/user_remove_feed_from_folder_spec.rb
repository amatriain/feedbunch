require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed
  end

  context 'remove feed from folder' do

    it 'removes a feed from a folder' do
      @folder.feeds.count.should eq 1
      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      @folder.feeds.count.should eq 0
    end

    it 'deletes the folder if it is empty' do
      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      Folder.exists?(id: @folder.id).should be false
    end

    it 'does not delete the folder if it is not empty' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      Folder.exists?(id: @folder.id).should be_true
    end

    it 'returns nil' do
      folder = @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      folder.should be_nil
    end

  end

end
