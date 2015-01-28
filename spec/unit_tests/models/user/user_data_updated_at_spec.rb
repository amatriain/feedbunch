require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @old_user_data_etag = @user.reload.user_data_etag
  end

  context 'touches user_data' do

    it 'when a subscription is added' do
      @user.subscribe @feed.fetch_url
      expect(@user.reload.user_data_etag).not_to eq @old_user_data_etag
    end

    it 'when a subscription is removed' do
      @user.subscribe @feed.fetch_url
      @old_user_data_etag = @user.reload.user_data_etag

      @user.unsubscribe @feed
      expect(@user.reload.user_data_etag).not_to eq @old_user_data_etag
    end
  end
end