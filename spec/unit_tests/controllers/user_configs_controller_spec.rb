require 'rails_helper'

describe Api::UserConfigsController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns success' do
      get :show, format: :json
      response.should be_success
    end
  end

end