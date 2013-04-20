require 'spec_helper'

describe Feed do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  context 'validations' do
    it 'accepts valid URLs' do
      @feed.url = 'http://www.xkcd.com'
      @feed.valid?.should be_true
    end

    it 'does not accept invalid URLs' do
      @feed.url = 'invalid_url'
      @feed.valid?.should be_false
    end

    it 'accepts an empty URL' do
      @feed.url = ''
      @feed.valid?.should be_true
      @feed.url = nil
      @feed.valid?.should be_true
    end

    it 'accepts duplicate URLs' do
      feed_dupe = FactoryGirl.build :feed, url: @feed.url
      feed_dupe.valid?.should be_true
    end

    it 'accepts valid fetch URLs' do
      @feed.fetch_url = 'http://www.xkcd.com/rss.xml'
      @feed.valid?.should be_true
    end

    it 'does not accept invalid fetch URLs' do
      @feed.fetch_url = 'invalid_url'
      @feed.valid?.should be_false
    end

    it 'does not accept an empty fetch URL' do
      @feed.fetch_url = ''
      @feed.valid?.should be_false
      @feed.fetch_url = nil
      @feed.valid?.should be_false
    end

    it 'does not accept duplicate fetch URLs' do
      feed_dupe = FactoryGirl.build :feed, fetch_url: @feed.fetch_url
      feed_dupe.valid?.should be_false
    end

    it 'does not accept an empty title' do
      @feed.title = ''
      @feed.valid?.should be_false
      @feed.title = nil
      @feed.valid?.should be_false
    end


  end

  context 'sanitization' do

    it 'sanitizes title' do
      unsanitized_title = '<script>alert("pwned!");</script>title'
      sanitized_title = 'title'
      feed = FactoryGirl.create :feed, title: unsanitized_title
      feed.title.should eq sanitized_title
    end

    it 'sanitizes url' do
      unsanitized_url = "http://xkcd.com<script>alert('pwned!');</script>"
      sanitized_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, url: unsanitized_url
      feed.url.should eq sanitized_url
    end

    it 'sanitizes fetch url' do
      unsanitized_url = "http://xkcd.com<script>alert('pwned!');</script>"
      sanitized_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, fetch_url: unsanitized_url
      feed.fetch_url.should eq sanitized_url
    end

  end

  context 'feed entries' do
    it 'deletes entries when deleting a feed' do
      entry1 = FactoryGirl.create :entry
      entry2 = FactoryGirl.create :entry
      @feed.entries << entry1 << entry2

      Entry.count.should eq 2

      @feed.destroy
      Entry.count.should eq 0
    end
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
end
