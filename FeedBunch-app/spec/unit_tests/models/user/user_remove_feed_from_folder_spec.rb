# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @user.subscribe @feed.fetch_url
    @folder = FactoryBot.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed
  end

  context 'remove feed from folder' do

    it 'removes a feed from a folder' do
      expect(@folder.feeds.count).to eq 1
      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      expect(@folder.feeds.count).to eq 0
    end

    it 'deletes the folder if it is empty' do
      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      expect(Folder.exists?(id: @folder.id)).to be false
    end

    it 'does not delete the folder if it is not empty' do
      feed2 = FactoryBot.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      expect(Folder.exists?(id: @folder.id)).to be true
    end

    it 'returns nil' do
      folder = @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
      expect(folder).to be_nil
    end

  end

end
