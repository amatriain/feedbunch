require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @title = 'New folder'
  end

  context 'add feed to new folder' do

    it 'creates new folder' do
      @user.add_feed_to_new_folder @feed.id, @title

      @user.reload
      @user.folders.where(title: @title).should be_present
    end

    it 'adds feed to new folder' do
      @user.add_feed_to_new_folder @feed.id, @title
      @user.reload

      folder = @user.folders.where(title: @title).first
      folder.feeds.count.should eq 1
      folder.feeds.should include @feed
    end

    it 'removes feed from its old folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      folder.feeds.count.should eq 1
      @user.add_feed_to_new_folder @feed.id, @title
      folder.feeds.count.should eq 0
    end

    it 'deletes old folder if it has no more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      @user.add_feed_to_new_folder @feed.id, @title
      Folder.exists?(folder).should be_false
    end

    it 'does not delete old folder if it has more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      folder.feeds << @feed << feed2

      @user.add_feed_to_new_folder @feed.id, @title
      Folder.exists?(folder).should be_true
    end

    it 'returns the new folder' do
      changed_data = @user.add_feed_to_new_folder @feed.id, @title
      folder = @user.folders.where(title: @title).first

      changed_data[:new_folder].should eq folder
    end

    it 'returns the old folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      changed_data = @user.add_feed_to_new_folder @feed.id, @title

      changed_data[:old_folder].should eq folder
    end

    it 'does not return the old folder if the feed was not in any folder' do
      changed_data = @user.add_feed_to_new_folder @feed.id, @title
      changed_data.keys.should_not include :old_folder
    end

    it 'raises an error if the user already has a folder with the same title' do
      folder = FactoryGirl.build :folder, user_id: @user.id, title: @title
      @user.folders << folder
      expect {@user.add_feed_to_new_folder @feed.id, @title}.to raise_error FolderAlreadyExistsError
    end

    it 'does not raise an error if another user has a folder with the same title' do
      user2 = FactoryGirl.create :user
      folder2 = FactoryGirl.build :folder, user_id: user2.id, title: @title
      user2.folders << folder2

      expect {@user.add_feed_to_new_folder @feed.id, @title}.to_not raise_error
    end

    it 'raises an error if user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.add_feed_to_new_folder feed2.id, @title}.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
