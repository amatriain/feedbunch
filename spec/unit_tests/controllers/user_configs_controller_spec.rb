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

    context 'show_main_tour flag' do

      it 'updates flag' do
        @user.update show_main_tour: true
        patch :update, {user_config: {show_main_tour: 'false'}}
        expect(@user.reload.show_main_tour).to be false
      end

      it 'does not update flag if a wrong param value is passed' do
        @user.update show_main_tour: true
        patch :update, {user_config: {show_main_tour: 'not_a_boolean'}}
        expect(@user.reload.show_main_tour).to be true
      end
    end

    context 'show_mobile_tour flag' do

      it 'updates flag' do
        @user.update show_mobile_tour: true
        patch :update, {user_config: {show_mobile_tour: 'false'}}
        expect(@user.reload.show_mobile_tour).to be false
      end

      it 'does not update flag if a wrong param value is passed'
    end
  end

end