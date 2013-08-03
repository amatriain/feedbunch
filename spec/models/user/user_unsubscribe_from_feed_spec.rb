require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'unsubscribe from feed' do
    it 'unsubscribes a user from a feed' do
      @user.feeds.exists?(@feed.id).should be_true
      @user.unsubscribe @feed
      @user.feeds.exists?(@feed.id).should be_false
    end

    it 'returns nil if feed was not in a folder' do
      @user.feeds.exists?(@feed.id).should be_true
      folder_unchanged = @user.unsubscribe @feed
      folder_unchanged.should be_nil
    end

    it 'returns folder id if feed was in a folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      old_folder = @user.unsubscribe @feed
      old_folder.should eq folder
    end

    it 'raises error if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.unsubscribe feed2}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'raises an error if there is a problem unsubscribing' do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      expect {@user.unsubscribe @feed}.to raise_error
    end

    it 'does not change subscriptions to the feed by other users' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.feeds.exists?(@feed.id).should be_true
      user2.feeds.exists?(@feed.id).should be_true

      @user.unsubscribe @feed
      Feed.exists?(@feed.id).should be_true
      @user.feeds.exists?(@feed.id).should be_false
      user2.feeds.exists?(@feed.id).should be_true
    end

    it 'completely deletes feed if there are no more users subscribed' do
      Feed.exists?(@feed.id).should be_true

      @user.unsubscribe @feed

      Feed.exists?(@feed.id).should be_false
    end

    it 'does not delete feed if there are more users subscribed' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.unsubscribe @feed
      Feed.exists?(@feed).should be_true
    end
  end

end
