require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryBot.create :user
    @folder = FactoryBot.build :folder, user_id: @user.id
    @user.folders << @folder
    @feed = FactoryBot.create :feed
    @user.subscribe @feed.fetch_url
  end

  context 'add feed to folder' do

    it 'adds a feed to a folder' do
      expect(@folder.feeds).to be_blank
      @user.move_feed_to_folder @feed, folder: @folder
      @folder.reload
      expect(@folder.feeds.count).to eq 1
      expect(@folder.feeds).to include @feed
    end

    it 'removes the feed from its old folder' do
      feed2 = FactoryBot.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed
      @folder.feeds << feed2

      folder2 = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      @folder.reload
      expect(@folder.feeds).not_to include @feed
    end

    it 'does not change feed/folder if asked to move feed to the same folder' do
      @folder.feeds << @feed

      @user.move_feed_to_folder @feed, folder: @folder

      expect(@folder.feeds.count).to eq 1
      expect(@folder.feeds).to include @feed
    end

    it 'returns the new folder' do
      folder = @user.move_feed_to_folder @feed, folder: @folder
      expect(folder).to eq @folder
    end

    it 'deletes the old folder if it had no more feeds' do
      @folder.feeds << @feed
      folder2 = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      expect(Folder.exists?(id: @folder.id)).to be false
    end

    it 'does not delete the old folder if it has more feeds' do
      feed2 = FactoryBot.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed << feed2
      folder2 = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.move_feed_to_folder @feed, folder: folder2

      expect(Folder.exists?(id: @folder.id)).to be true
    end
  end
end
