require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'add feed to folder' do

    it 'adds a feed to a folder' do
      @folder.feeds.should be_blank
      @user.move_feed_to_folder @feed, folder: @folder
      @folder.reload
      @folder.feeds.count.should eq 1
      @folder.feeds.should include @feed
    end

    it 'removes the feed from its old folder' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed
      @folder.feeds << feed2

      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      @folder.reload
      @folder.feeds.should_not include @feed
    end

    it 'does not change feed/folder if asked to move feed to the same folder' do
      @folder.feeds << @feed

      @user.move_feed_to_folder @feed, folder: @folder

      @folder.feeds.count.should eq 1
      @folder.feeds.should include @feed
    end

    it 'returns the new folder' do
      folder = @user.move_feed_to_folder @feed, folder: @folder
      folder.should eq @folder
    end

    it 'deletes the old folder if it had no more feeds' do
      @folder.feeds << @feed
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      Folder.exists?(id: @folder.id).should be_false
    end

    it 'does not delete the old folder if it has more feeds' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed << feed2
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      Folder.exists?(id: @folder.id).should be_true
    end
  end
end
