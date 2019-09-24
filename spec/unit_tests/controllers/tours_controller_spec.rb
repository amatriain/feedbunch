# frozen_string_literal: true

require 'rails_helper'

describe Api::ToursController, type: :controller do

  before :each do
    @user = FactoryBot.create :user
    login_user_for_unit @user
  end

  context 'GET show_main' do

    it 'returns success' do
      get :show_main, format: :json
      expect(response).to be_successful
    end
  end

  context 'GET show_mobile' do

    it 'returns success' do
      get :show_mobile, format: :json
      expect(response).to be_successful
    end
  end

end