require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @old_folders_etag = @user.reload.folders_etag
  end

  context 'touches folders' do

    it 'when a folder is created' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      expect(@user.reload.folders_etag).not_to eq @old_folders_etag
    end

    it 'when a folder is destroyed' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      @old_folders_etag = @user.reload.folders_etag

      folder.destroy
      expect(@user.reload.folders_etag).not_to eq @old_folders_etag
    end
  end
end