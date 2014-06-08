require 'rails_helper'

describe FeedSubscription, type: :model do

  before :each do
    @feed_subscription = FactoryGirl.create :feed_subscription
  end

  context 'validations' do

    it 'does not accept empty user' do
      feed_subscription = FactoryGirl.build :feed_subscription, user_id: nil
      expect(feed_subscription).not_to be_valid
    end

    it 'does not accept empty feed' do
      feed_subscription = FactoryGirl.build :feed_subscription, feed_id: nil
      expect(feed_subscription).not_to be_valid
    end

    it 'gives a default value of zero to the unread entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: nil
      feed_subscription.save!
      expect(feed_subscription.unread_entries).to eq 0
    end

    it 'does not accept decimal unread_entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: 1.1
      expect(feed_subscription).not_to be_valid
    end

    it 'defaults to zero if passed a negative unread_entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: -1
      feed_subscription.save!
      expect(feed_subscription.unread_entries).to eq 0
    end

    it 'does not accept multiple subscriptions for the same feed and user' do
      feed_subscription = FactoryGirl.create :feed_subscription
      feed_subscription_dupe = FactoryGirl.build :feed_subscription,
                                                 user_id: feed_subscription.user_id,
                                                 feed_id: feed_subscription.feed_id
      expect(feed_subscription_dupe).not_to be_valid
    end

    it 'accepts multiple subscriptions for the same feed and different users' do
      feed_subscription = FactoryGirl.create :feed_subscription
      user2 = FactoryGirl.create :user
      feed_subscription2 = FactoryGirl.build :feed_subscription,
                                             feed_id: feed_subscription.feed_id,
                                             user_id: user2.id
      expect(feed_subscription2).to be_valid
    end

    it 'accepts multiple subscriptions for the same user and different feeds' do
      feed_subscription = FactoryGirl.create :feed_subscription
      feed2 = FactoryGirl.create :feed
      feed_subscription2 = FactoryGirl.build :feed_subscription,
                                             feed_id: feed2.id,
                                             user_id: feed_subscription.user_id
      expect(feed_subscription2).to be_valid
    end
  end
end