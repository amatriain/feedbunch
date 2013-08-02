require 'spec_helper'

describe User do
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
      @user.add_feed_to_folder @feed.id, @folder.id
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

      @user.add_feed_to_folder @feed.id, folder2.id

      @folder.reload
      @folder.feeds.should_not include @feed
    end

    it 'does not change feed/folder if asked to move feed to the same folder' do
      @folder.feeds << @feed

      @user.add_feed_to_folder @feed.id, @folder.id

      @folder.feeds.count.should eq 1
      @folder.feeds.should include @feed
    end

    it 'returns the feed' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:feed].should eq @feed
    end

    it 'returns the new folder' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:new_folder].should eq @folder
    end

    it 'returns the old folder' do
      @folder.feeds << @feed
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      folders = @user.add_feed_to_folder @feed.id, folder2.id
      folders[:old_folder].should eq @folder
    end

    it 'does not return the old folder if the feed was not in a folder' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:old_folder].should be_nil
    end

    it 'deletes the old folder if it had no more feeds' do
      @folder.feeds << @feed
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.add_feed_to_folder @feed.id, folder2.id

      Folder.exists?(id: @folder.id).should be_false
    end

    it 'does not delete the old folder if it has more feeds' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed << feed2
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.add_feed_to_folder @feed.id, folder2.id

      Folder.exists?(id: @folder.id).should be_true
    end

    it 'raises an error if the folder does not belong to the user' do
      folder = FactoryGirl.create :folder
      expect {@user.add_feed_to_folder @feed.id, folder.id}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'raises an error if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      expect {@user.add_feed_to_folder feed.id, @folder.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
