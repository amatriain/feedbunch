require 'rails_helper'

describe Api::TourI18nsController, type: :controller do

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

end