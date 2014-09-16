require 'rails_helper'

describe Api::UserConfigsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
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
      patch :update, {user_config: {show_main_tour: 'false'}}
      expect(response).to be_success
    end

    it 'updates user config' do
      @user.update show_main_tour: true
      patch :update, {user_config: {show_main_tour: 'false'}}
      expect(@user.reload.show_main_tour).to be false
    end

    it 'does not update user config if a wrong param value is passed' do
      @user.update show_main_tour: true
      patch :update, {user_config: {show_main_tour: 'not_a_boolean'}}
      expect(@user.reload.show_main_tour).to be true
    end
  end

end