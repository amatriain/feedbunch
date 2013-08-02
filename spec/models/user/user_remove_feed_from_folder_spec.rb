require 'spec_helper'

describe User do
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
      @user.remove_feed_from_folder @feed.id
      @folder.feeds.count.should eq 0
    end

    it 'deletes the folder if it is empty' do
      @user.remove_feed_from_folder @feed.id
      Folder.exists?(id: @folder.id).should be_false
    end

    it 'does not delete the folder if it is not empty' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      @user.remove_feed_from_folder @feed.id
      Folder.exists?(id: @folder.id).should be_true
    end

    it 'returns the folder object if it the feed was in a folder' do
      folder = @user.remove_feed_from_folder @feed.id
      folder.should eq @folder
    end

    it 'does not return a folder object if it the feed was not in a folder' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url

      folder = @user.remove_feed_from_folder feed2.id
      folder.should be_nil
    end

    it 'returns a folder object with no feeds if there are no more feeds in it' do
      folder = @user.remove_feed_from_folder @feed.id
      folder.feeds.blank?.should be_true
    end

    it 'returns a folder object with feeds if there are more feeds in it' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      folder = @user.remove_feed_from_folder @feed.id
      folder.feeds.blank?.should be_false
    end

    it 'raises an error if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.remove_feed_from_folder feed2.id}.to raise_error ActiveRecord::RecordNotFound
    end

  end

end
