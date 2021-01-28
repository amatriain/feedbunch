# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryBot.create :user
    @old_folders_updated_at = @user.reload.folders_updated_at
  end

  context 'touches folders' do

    it 'when a folder is created' do
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      expect(@user.reload.folders_updated_at).not_to eq @old_folders_updated_at
    end

    it 'when a folder is destroyed' do
      folder = FactoryBot.build :folder, user_id: @user.id
      @user.folders << folder
      @old_folders_updated_at = @user.reload.folders_updated_at

      folder.destroy
      expect(@user.reload.folders_updated_at).not_to eq @old_folders_updated_at
    end
  end
end