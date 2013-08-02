require 'spec_helper'

describe FeedSubscription do

  before :each do
    @feed_subscription = FactoryGirl.create :feed_subscription
  end

  context 'validations' do

    it 'does not accept empty user' do
      feed_subscription = FactoryGirl.build :feed_subscription, user_id: nil
      feed_subscription.should_not be_valid
    end

    it 'does not accept empty feed' do
      feed_subscription = FactoryGirl.build :feed_subscription, feed_id: nil
      feed_subscription.should_not be_valid
    end

    it 'gives a default value of zero to the unread entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: nil
      feed_subscription.save!
      feed_subscription.unread_entries.should eq 0
    end

    it 'does not accept decimal unread_entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: 1.1
      feed_subscription.should_not be_valid
    end

    it 'does not accept negative unread_entries count' do
      feed_subscription = FactoryGirl.build :feed_subscription, unread_entries: -1
      feed_subscription.should_not be_valid
    end

    it 'does not accept multiple subscriptions for the same feed and user' do
      feed_subscription = FactoryGirl.create :feed_subscription
      feed_subscription_dupe = FactoryGirl.build :feed_subscription,
                                                 user_id: feed_subscription.user_id,
                                                 feed_id: feed_subscription.feed_id
      feed_subscription_dupe.should_not be_valid
    end

    it 'accepts multiple subscriptions for the same feed and different users' do
      feed_subscription = FactoryGirl.create :feed_subscription
      user2 = FactoryGirl.create :user
      feed_subscription2 = FactoryGirl.build :feed_subscription,
                                             feed_id: feed_subscription.feed_id,
                                             user_id: user2.id
      feed_subscription2.should be_valid
    end

    it 'accepts multiple subscriptions for the same user and different feeds' do
      feed_subscription = FactoryGirl.create :feed_subscription
      feed2 = FactoryGirl.create :feed
      feed_subscription2 = FactoryGirl.build :feed_subscription,
                                             feed_id: feed2.id,
                                             user_id: feed_subscription.user_id
      feed_subscription2.should be_valid
    end
  end
end