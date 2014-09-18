require 'rails_helper'

describe Api::ToursController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'GET show_main' do

    it 'returns success' do
      get :show_main, format: :json
      expect(response).to be_success
    end
  end

end