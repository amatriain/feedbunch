require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @old_folders_updated_at = @user.folders_updated_at
  end

  context 'touches folders' do

    it 'when a folder is created' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      expect(@user.reload.folders_updated_at).to be > @old_folders_updated_at
    end

    it 'when a folder is destroyed' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      @old_folders_updated_at = @user.reload.folders_updated_at

      folder.destroy
      expect(@user.reload.folders_updated_at).to be > @old_folders_updated_at
    end
  end
end