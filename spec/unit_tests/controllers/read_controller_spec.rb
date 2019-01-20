require 'rails_helper'

describe ReadController, type: :controller do

  before :each do
    @user = FactoryBot.create :user

    @feed1 = FactoryBot.create :feed
    @feed2 = FactoryBot.create :feed
    @user.subscribe @feed1.fetch_url

    @folder1 = FactoryBot.build :folder, user_id: @user.id
    @folder2 = FactoryBot.create :folder
    @user.folders << @folder1

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns success' do
      get :index
      expect(response).to be_successful
    end
  end
end
