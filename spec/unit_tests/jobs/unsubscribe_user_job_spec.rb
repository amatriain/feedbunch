require 'rails_helper'

describe UnsubscribeUserJob do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'unsubscribes user from feed' do
    @user.feeds.should include @feed
    UnsubscribeUserJob.perform @user.id, @feed.id
    @user.reload
    @user.feeds.should_not include @feed
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      User.any_instance.should_not_receive :unsubscribe
      UnsubscribeUserJob.perform 1234567890, @feed.id
    end

    it 'does nothing if the feed does not exist' do
      @user.should_not_receive :unsubscribe
      UnsubscribeUserJob.perform @user.id, 1234567890
    end

    it 'does nothing if the feed is not subscribed by the user' do
      folder = FactoryGirl.create :folder
      @user.should_not_receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, folder.id, false, nil
    end

  end
end