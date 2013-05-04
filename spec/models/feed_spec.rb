require 'spec_helper'

describe Feed do

  before :each do
    @feed = FactoryGirl.create :feed

    # ensure no actual HTTP calls are made
    RestClient.stub :get
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
      entry1 = FactoryGirl.build :entry
      entry2 = FactoryGirl.build :entry
      @feed.entries << entry1 << entry2

      Entry.count.should eq 2

      @feed.destroy
      Entry.count.should eq 0
    end
  end

  context 'user suscriptions' do
    before :each do
      @user1 = FactoryGirl.build :user
      @user2 = FactoryGirl.build :user
      @user3 = FactoryGirl.build :user
      @feed.users << @user1 << @user2
    end

    it 'returns user suscribed to the feed' do
      @feed.users.should include @user1
      @feed.users.should include @user2
    end

    it 'does not return users not suscribed to the feed' do
      @feed.users.should_not include @user3
    end
  end

  context 'association with folders' do
    before :each do
      @folder1 = FactoryGirl.build :folder
      @folder2 = FactoryGirl.build :folder
      @folder3 = FactoryGirl.build :folder
      @feed.folders << @folder1 << @folder2
    end

    it 'returns folders to which this feed is associated' do
      @feed.folders.should include @folder1
      @feed.folders.should include @folder2
    end

    it 'does not return folders to which this feed is not associated' do
      @feed.folders.should_not include @folder3
    end
  end

  context 'add subscription' do

    before :each do
      @user = FactoryGirl.create :user
      FeedClient.stub fetch: true
    end

    it 'rejects non-valid URLs' do
      invalid_url = 'not-an-url'
      result = Feed.subscribe invalid_url, @user.id
      result.should be_false
      @user.feeds.where(fetch_url: invalid_url).should be_blank
      @user.feeds.where(url: invalid_url).should be_blank
    end

    it 'accepts URLs without scheme, defaults to http://' do
      url = 'xkcd.com'
      result = Feed.subscribe url, @user.id
      result.should be_true
      @user.feeds.where(fetch_url: 'http://'+url).should be_present
    end

    it 'subscribes user to feed already in the database, given its fetch_url' do
      # At first the user is not subscribed to the feed
      @user.feeds.where(fetch_url: @feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe @feed.fetch_url, @user.id
      result.should eq @feed
      @user.feeds.where(fetch_url: @feed.fetch_url).first.should eq @feed
    end

    it 'subscribes user to feed already in the database, given its url' do
      # At first the user is not subscribed to the feed
      @user.feeds.where(url: @feed.url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe @feed.url, @user.id
      result.should eq @feed
      @user.feeds.where(url: @feed.url).first.should eq @feed
    end

    it 'adds new feed to the database and subscribes user to it' do
      feed_url = 'http://a.new.feed.url.com'
      entry_title1 = 'an entry title'
      entry_title2 = 'another entry title'
      FeedClient.stub :fetch do
        feed = Feed.where(fetch_url: feed_url).first
        entry1 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title1
        entry2 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title2
        feed.entries << entry1 << entry2
        true
      end

      # At first the user is not subscribed to the feed
      @user.feeds.where(fetch_url: feed_url).should be_blank

      Feed.subscribe feed_url, @user.id
      @user.feeds.where(fetch_url: feed_url).should be_present
      @user.feeds.where(fetch_url: feed_url).first.entries.count.should eq 2
      @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title1).should be_present
      @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title2).should be_present
    end

    it 'does not save in the database if there is a problem fetching the feed' do
      feed_url = 'http://a.new.feed.url.com'
      FeedClient.stub fetch: false

      # At first the user is not subscribed to any feed
      @user.feeds.should be_blank
      Feed.subscribe feed_url, @user.id
      # User should still be subscribed to no feeds, and the feed should not be saved in the database
      @user.feeds.should be_blank
      Feed.where(fetch_url: feed_url).should be_blank
      Feed.where(url: feed_url).should be_blank
    end

    it 'returns false if it cannot fetch the feed' do
      feed_url = 'http://a.new.feed.url.com'
      FeedClient.stub fetch: false

      # At first the user is not subscribed to any feed
      success = Feed.subscribe feed_url, @user.id
      success.should be_false
    end

  end
end
