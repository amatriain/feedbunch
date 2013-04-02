require 'spec_helper'

describe Feed do
  before :each do
    @feed = FactoryGirl.create :feed
  end

  context 'user suscriptions' do
    before :each do
      @user1 = FactoryGirl.create :user
      @user2 = FactoryGirl.create :user
      @user3 = FactoryGirl.create :user
      @feed.users << @user1 << @user2
    end

    it 'returns user suscribed to the feed' do
      @feed.users.include?(@user1).should be_true
      @feed.users.include?(@user2).should be_true
    end

    it 'does not return users not suscribed to the feed' do
      @feed.users.include?(@user3).should be_false
    end

  end

  it 'accepts valid URLs' do
    @feed.url = 'http://www.xkcd.com/rss.xml'
    @feed.valid?.should be_true
  end

  it 'does not accept invalid URLs' do
    @feed.url = 'invalid_url'
    @feed.valid?.should be_false
  end

  it 'does not accept an empty URL' do
    @feed.url = ''
    @feed.valid?.should be_false
    @feed.url = nil
    @feed.valid?.should be_false
  end

  it 'does not accept an empty title' do
    @feed.title = ''
    @feed.valid?.should be_false
    @feed.title = nil
    @feed.valid?.should be_false
  end

  it 'does not accept duplicate URLs' do
    feed_dupe = FactoryGirl.build :feed, url: @feed.url
    feed_dupe.valid?.should be_false
  end
end
