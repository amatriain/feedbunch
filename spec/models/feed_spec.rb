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

    it 'does not allow the same entry more than once' do
      entry = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry
      @feed.entries << entry

      @feed.entries.count.should eq 1
      @feed.entries.where(id: entry.id).count.should eq 1
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

    it 'does not allow subscribing the same user more than once' do
      @feed.users.count.should eq 2
      @feed.users.where(id: @user1.id).count.should eq 1

      @feed.users << @user1
      @feed.users.count.should eq 2
      @feed.users.where(id: @user1.id).count.should eq 1
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

    it 'does not allow associating with the same folder more than once' do
      @feed.folders.count.should eq 2
      @feed.folders.where(id: @folder1.id).count.should eq 1

      @feed.folders << @folder1
      @feed.folders.count.should eq 2
      @feed.folders.where(id: @folder1.id).count.should eq 1
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

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url' do
      # User is already subscribed to the feed
      @user.feeds << @feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe @feed.fetch_url, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_no_slash, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_slash, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_no_scheme, @user.id}.to raise_error AlreadySubscribedError
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

    it 'subscribes user to feed already in the database, given its fetch_url with added trailing slash' do
      url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_slash, @user.id
      result.should eq feed
      @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
    end

    it 'subscribes user to feed already in the database, given its fetch_url missing a trailing slash' do
      url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_no_slash, @user.id
      result.should eq feed
      @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
    end

    it 'subscribes user to feed already in the database, given its fetch_url without uri-scheme' do
      url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_no_scheme, @user.id
      result.should eq feed
      @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url' do
      # User is already subscribed to the feed
      @user.feeds << @feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe @feed.url, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_no_slash, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_slash, @user.id}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.feeds << feed

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{Feed.subscribe url_no_scheme, @user.id}.to raise_error AlreadySubscribedError
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

    it 'subscribes user to feed already in the database, given its url with added trailing slash' do
      url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      @user.feeds.where(url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_slash, @user.id
      result.should eq feed
      @user.feeds.where(url: feed.url).first.should eq feed
    end

    it 'subscribes user to feed already in the database, given its url missing a trailing slash' do
      url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      @user.feeds.where(url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_no_slash, @user.id
      result.should eq feed
      @user.feeds.where(url: feed.url).first.should eq feed
    end

    it 'subscribes user to feed already in the database, given its url without uri-scheme' do
      url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      @user.feeds.where(url: feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = Feed.subscribe url_no_scheme, @user.id
      result.should eq feed
      @user.feeds.where(url: feed.url).first.should eq feed
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

  context 'unsubscribe from feed' do

    before :each do
      @user = FactoryGirl.create :user
      @user.feeds << @feed
    end

    it 'unsubscribes a user from a feed' do
      @user.feeds.exists?(@feed.id).should be_true
      Feed.unsubscribe @feed.id, @user.id
      @user.feeds.exists?(@feed.id).should be_false
    end

    it 'returns true if successful' do
      @user.feeds.exists?(@feed.id).should be_true
      success = Feed.unsubscribe @feed.id, @user.id
      success.should be_true
    end

    it 'returns false if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      success = Feed.unsubscribe feed2.id, @user.id
      success.should be_false
    end

    it 'returns false if there is a problem unsubscribing' do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      success = Feed.unsubscribe @feed.id, @user.id
      success.should be_false
    end

    it 'does not change subscriptions to the feed by other users' do
      user2 = FactoryGirl.create :user
      user2.feeds << @feed

      @user.feeds.exists?(@feed.id).should be_true
      user2.feeds.exists?(@feed.id).should be_true

      success = Feed.unsubscribe @feed.id, @user.id
      Feed.exists?(@feed.id).should be_true
      @user.feeds.exists?(@feed.id).should be_false
      user2.feeds.exists?(@feed.id).should be_true
      success.should be_true
    end

    it 'completely deletes feed if there are no more users subscribed' do
      Feed.exists?(@feed.id).should be_true

      Feed.unsubscribe @feed.id, @user.id

      Feed.exists?(@feed.id).should be_false
    end

  end
end
