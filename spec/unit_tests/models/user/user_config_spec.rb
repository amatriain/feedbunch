require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user,
                               show_main_tour: true,
                               show_mobile_tour: true,
                               show_feed_tour: true,
                               show_entry_tour: true,
                               show_kb_shortcuts_tour: true
  end

  context 'user configuration' do

    it 'updates config' do
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be true

      @user.update_config show_main_tour: false,
                          show_mobile_tour: false,
                          show_feed_tour: false,
                          show_entry_tour: false,
                          show_kb_shortcuts_tour: false

      @user.reload
      expect(@user.show_main_tour).to be false
      expect(@user.show_mobile_tour).to be false
      expect(@user.show_feed_tour).to be false
      expect(@user.show_entry_tour).to be false
      expect(@user.show_kb_shortcuts_tour).to be false
    end

    it 'updates only show_main_tour flag' do
      @user.update_config show_main_tour: false

      @user.reload
      expect(@user.show_main_tour).to be false
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be true
    end

    it 'updates only show_mobile_tour flag' do
      @user.update_config show_mobile_tour: false

      @user.reload
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be false
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be true
    end

    it 'updates only show_feed_tour flag' do
      @user.update_config show_feed_tour: false

      @user.reload
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be false
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be true
    end

    it 'updates only show_entry_tour flag' do
      @user.update_config show_entry_tour: false

      @user.reload
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be false
      expect(@user.show_kb_shortcuts_tour).to be true
    end

    it 'updates only show_kb_shortcuts_tour flag' do
      @user.update_config show_kb_shortcuts_tour: false

      @user.reload
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be false
    end

    it 'updates nothing' do
      @user.update_config

      @user.reload
      expect(@user.show_main_tour).to be true
      expect(@user.show_mobile_tour).to be true
      expect(@user.show_feed_tour).to be true
      expect(@user.show_entry_tour).to be true
      expect(@user.show_kb_shortcuts_tour).to be true
    end
  end
end
