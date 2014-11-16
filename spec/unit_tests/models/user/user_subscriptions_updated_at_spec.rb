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

    context 'changes to subscribed feeed' do

      before :each do
        @feed = FactoryGirl.create :feed
        @user.subscribe @feed.fetch_url
        @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
      end

      it 'when unsubscribed from a feed' do
        @user.unsubscribe @feed
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end

      it 'when feed title changes' do
        @feed.reload.update title: 'another title'
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end

      it 'when feed URL changes' do
        @feed.reload.update url: 'http://another.url.com'
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end
    end

    context 'unread entries count' do

      it 'when unread entries count for a feed is incremented' do

      end

      it 'when unread entries for a feed is decremented'

      it 'when unread entries count for a feed is set to zero'
    end

    context 'folder changes' do

      it 'when feed is moved into a folder'

      it 'when feed is moved out of a folder'
    end
  end
end