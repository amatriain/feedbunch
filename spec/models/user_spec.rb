require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  it 'returns feeds the user is suscribed to' do
    feed1 = FactoryGirl.create :feed
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed1 << feed2
    @user.feeds.include?(feed1).should be_true
    @user.feeds.include?(feed2).should be_true
  end

  it 'does not return feeds the user is not suscribed to' do
    feed = FactoryGirl.create :feed
    @user.feeds.include?(feed).should be_false
  end

  it 'does not allow duplicate usernames' do
    user_dupe = FactoryGirl.build :user, email: @user.email
    user_dupe.valid?.should be_false
  end
end
