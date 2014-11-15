require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @old_subscriptions_updated_at = @user.subscriptions_updated_at
  end

  context 'touches subscriptions' do

    it 'when subscribed to a new feed' do
      feed = FactoryGirl.create :feed
      @user.subscribe feed.fetch_url
      expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
    end

    it 'when unsubscribed from a feed' do
      feed = FactoryGirl.create :feed
      @user.subscribe feed.fetch_url
      old_subscriptions_updated_at = @user.reload.subscriptions_updated_at

      @user.unsubscribe feed
      expect(@user.reload.subscriptions_updated_at).to be > old_subscriptions_updated_at
    end

    it 'when feed title changes'

    it 'when feed URL changes'

    context 'unread entries count' do

      it 'when unread entries count for a feed is incremented'

      it 'when unread entries for a feed is decremented'

      it 'when unread entries count for a feed is set to zero'
    end

    context 'folder changes' do

      it 'when feed is moved into a folder'

      it 'when feed is moved out of a folder'
    end
  end
end