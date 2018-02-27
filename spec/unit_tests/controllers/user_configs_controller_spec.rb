require 'rails_helper'

describe Api::UserConfigsController, type: :controller do

  before :each do
    @user = FactoryBot.create :user,
                               show_main_tour: true,
                               show_mobile_tour: true,
                               show_feed_tour: true,
                               show_entry_tour: true,
                               show_kb_shortcuts_tour: true
    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns success' do
      get :show, format: :json
      expect(response).to be_success
    end
  end

  context 'PATCH update' do

    it 'returns success' do
      patch :update, params: {user_config: {show_main_tour: 'false',
                                    show_mobile_tour: 'false',
                                    show_feed_tour: 'false',
                                    show_entry_tour: 'false',
                                    show_kb_shortcuts_tour: 'false'}}
      expect(response).to be_success
    end

    context 'all flags' do

      it 'updates all config flags' do
        patch :update, params: {user_config: {show_main_tour: 'false',
                                      show_mobile_tour: 'false',
                                      show_feed_tour: 'false',
                                      show_entry_tour: 'false',
                                      show_kb_shortcuts_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be false
        expect(@user.show_mobile_tour).to be false
        expect(@user.show_feed_tour).to be false
        expect(@user.show_entry_tour).to be false
        expect(@user.show_kb_shortcuts_tour).to be false
      end
    end

    context 'show_main_tour flag' do

      it 'updates flag' do
        patch :update, params: {user_config: {show_main_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be false
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end

      it 'does not update flag if a wrong param value is passed' do
        patch :update, params: {user_config: {show_main_tour: 'not_a_boolean'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end
    end

    context 'show_mobile_tour flag' do

      it 'updates flag' do
        patch :update, params: {user_config: {show_mobile_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be false
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end

      it 'does not update flag if a wrong param value is passed' do
        patch :update, params: {user_config: {show_mobile_tour: 'not_a_boolean'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end
    end

    context 'show_feed_tour flag' do

      it 'updates flag' do
        patch :update, params: {user_config: {show_feed_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be false
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end

      it 'does not update flag if a wrong param value is passed' do
        patch :update, params: {user_config: {show_feed_tour: 'not_a_boolean'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end
    end

    context 'show_entry_tour flag' do

      it 'updates flag' do
        patch :update, params: {user_config: {show_entry_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be false
        expect(@user.show_kb_shortcuts_tour).to be true
      end

      it 'does not update flag if a wrong param value is passed' do
        patch :update, params: {user_config: {show_entry_tour: 'not_a_boolean'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end
    end

    context 'show_kb_shortcuts_tour flag' do

      it 'updates flag' do
        patch :update, params: {user_config: {show_kb_shortcuts_tour: 'false'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be false
      end

      it 'does not update flag if a wrong param value is passed' do
        patch :update, params: {user_config: {show_kb_shortcuts_tour: 'not_a_boolean'}}
        @user.reload
        expect(@user.show_main_tour).to be true
        expect(@user.show_mobile_tour).to be true
        expect(@user.show_feed_tour).to be true
        expect(@user.show_entry_tour).to be true
        expect(@user.show_kb_shortcuts_tour).to be true
      end
    end
  end

end