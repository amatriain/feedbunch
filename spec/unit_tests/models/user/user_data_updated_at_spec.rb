require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @old_user_data_updated_at = @user.reload.user_data_updated_at
  end

  context 'touches user_data' do

    it 'when a subscription is added' do
      @user.subscribe @feed.fetch_url
      expect(@user.reload.user_data_updated_at).to be > @old_user_data_updated_at
    end

    it 'when a subscription is removed' do
      @user.subscribe @feed.fetch_url
      @old_user_data_updated_at = @user.reload.user_data_updated_at

      @user.unsubscribe @feed
      expect(@user.reload.user_data_updated_at).to be > @old_user_data_updated_at
    end
  end
end