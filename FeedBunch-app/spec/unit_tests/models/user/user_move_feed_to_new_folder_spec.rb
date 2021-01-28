# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @user.subscribe @feed.fetch_url
    @title = 'New folder'
  end

  context 'add feed to new folder' do

    it 'creates new folder' do
      @user.move_feed_to_folder @feed, folder_title: @title

      @user.reload
      expect(@user.folders.where(title: @title)).to be_present
    end

    it 'adds feed to new folder' do
      @user.move_feed_to_folder @feed, folder_title: @title
      @user.reload

      folder = @user.folders.find_by title: @title
      expect(folder.feeds.count).to eq 1
      expect(folder.feeds).to include @feed
    end

    it 'removes feed from its old folder' do
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      expect(folder.feeds.count).to eq 1
      @user.move_feed_to_folder @feed, folder_title: @title
      expect(folder.feeds.count).to eq 0
    end

    it 'deletes old folder if it has no more feeds' do
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      @user.move_feed_to_folder @feed, folder_title: @title
      expect(Folder.exists? folder.id).to be false
    end

    it 'does not delete old folder if it has more feeds' do
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      feed2 = FactoryBot.create :feed
      @user.subscribe feed2.fetch_url
      folder.feeds << @feed << feed2

      @user.move_feed_to_folder @feed, folder_title: @title
      expect(Folder.exists? folder.id).to be true
    end

    it 'returns the new folder' do
      folder = @user.move_feed_to_folder @feed, folder_title: @title
      expect(folder.user_id).to eq @user.id
      expect(folder.title).to eq @title
    end

    it 'raises an error if the user already has a folder with the same title' do
      folder = FactoryBot.build :folder, user_id: @user.id, title: @title
      @user.folders << folder
      expect {@user.move_feed_to_folder @feed, folder_title: @title}.to raise_error FolderAlreadyExistsError
    end

    it 'does not raise an error if another user has a folder with the same title' do
      user2 = FactoryBot.create :user
      folder2 = FactoryBot.build :folder, user_id: user2.id, title: @title
      user2.folders << folder2

      expect {@user.move_feed_to_folder @feed, folder_title: @title}.not_to raise_error
    end

    it 'raises an error if user is not subscribed to the feed' do
      feed2 = FactoryBot.create :feed
      expect {@user.move_feed_to_folder feed2, folder_title: @title}.to raise_error NotSubscribedError
    end
  end
end
