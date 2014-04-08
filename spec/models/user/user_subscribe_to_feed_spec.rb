require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
  end

  context 'enqueue a job to subscribe to a feed' do

    it 'enqueues a job to subscribe to the feed' do
      Resque.should_receive(:enqueue) do |job_class, user_id, fetch_url, folder_id, running_data_import|
        job_class.should eq SubscribeUserJob
        user_id.should eq @user.id
        fetch_url.should eq @feed.fetch_url
        folder_id.should be_nil
        running_data_import.should be_false
      end

      @user.enqueue_subscribe_job @feed.fetch_url
    end

    it 'creates a subscribe_job_state with state RUNNING' do
      SubscribeJobState.count.should eq 0

      @user.enqueue_subscribe_job @feed.fetch_url

      SubscribeJobState.count.should eq 1
      job_state = SubscribeJobState.first
      job_state.user_id.should eq @user.id
      job_state.fetch_url.should eq @feed.fetch_url
      job_state.state.should eq RefreshFeedJobState::RUNNING
    end

    it 'does not enqueue job if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url
      Resque.should_not_receive :enqueue
      @user.enqueue_subscribe_job @feed.fetch_url
    end

    it 'sets subscribe_job_state to state SUCCESS if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url

      @user.enqueue_subscribe_job @feed.fetch_url

      job_state = SubscribeJobState.first
      job_state.user_id.should eq @user.id
      job_state.fetch_url.should eq @feed.fetch_url
      job_state.state.should eq RefreshFeedJobState::SUCCESS
    end

  end

  context 'subscribe to feed immediately' do

    it 'does not allow subscribing to the same feed more than once' do
      @user.subscribe @feed.fetch_url
      expect {@user.subscribe @feed.fetch_url}.to raise_error
      @user.feeds.count.should eq 1
      @user.feeds.first.should eq @feed
    end

    it 'rejects non-valid URLs' do
      invalid_url = 'not-an-url'
      expect{@user.subscribe invalid_url}.to raise_error
      @user.feeds.where(fetch_url: invalid_url).should be_blank
      @user.feeds.where(url: invalid_url).should be_blank
    end

    it 'accepts URLs without scheme, defaults to http://' do
      url = 'xkcd.com/'
      FeedClient.stub :fetch do |feed, perform_autodiscovery|
        feed
      end

      result = @user.subscribe url

      result.should be_present
      feed = @user.feeds.where(fetch_url: 'http://'+url).first
      feed.should be_present
      result.should eq feed
    end

    it 'accepts URLs with feed:// scheme, defaults to http://' do
      url_feed = 'feed://xkcd.com/'
      url_http = 'http://xkcd.com/'
      FeedClient.stub :fetch do |feed, perform_autodiscovery|
        feed
      end

      result = @user.subscribe url_feed

      result.should be_present
      feed = @user.feeds.where(fetch_url: url_http).first
      feed.should be_present
      result.should eq feed
    end

    it 'accepts URLs with feed: scheme, defaults to http://' do
      url_feed = 'feed:http://xkcd.com/'
      url_http = 'http://xkcd.com/'
      FeedClient.stub :fetch do |feed, perform_autodiscovery|
        feed
      end

      result = @user.subscribe url_feed

      result.should be_present
      feed = @user.feeds.where(fetch_url: url_http).first
      feed.should be_present
      result.should eq feed
    end

    it 'subscribes to the feed actually fetched, not necessarily to a new one' do
      url = 'xkcd.com'
      existing_feed = FactoryGirl.create :feed
      FeedClient.stub :fetch do
        existing_feed
      end

      result = @user.subscribe url

      result.should eq existing_feed
      @user.feeds.count.should eq 1
      @user.feeds.should include existing_feed
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url' do
      # User is already subscribed to the feed
      @user.subscribe @feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe @feed.fetch_url}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
    end

    it 'subscribes user to feed already in the database, given its fetch_url' do
      # At first the user is not subscribed to the feed
      @user.feeds.where(fetch_url: @feed.fetch_url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = @user.subscribe @feed.fetch_url
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

      result = @user.subscribe url_slash
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

      result = @user.subscribe url_no_slash
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

      result = @user.subscribe url_no_scheme
      result.should eq feed
      @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url' do
      # User is already subscribed to the feed
      @user.subscribe @feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe @feed.url}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
    end

    it 'subscribes user to feed already in the database, given its url' do
      # At first the user is not subscribed to the feed
      @user.feeds.where(url: @feed.url).should be_blank

      # The feed is already in the database, no attempt to save it should happen
      Feed.any_instance.should_not_receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      FeedClient.should_not_receive :fetch

      result = @user.subscribe @feed.url
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

      result = @user.subscribe url_slash
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

      result = @user.subscribe url_no_slash
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

      result = @user.subscribe url_no_scheme
      result.should eq feed
      @user.feeds.where(url: feed.url).first.should eq feed
    end

    it 'adds new feed to the database and subscribes user to it' do
      feed_url = 'http://a.new.feed.url.com/'
      entry_title1 = 'an entry title'
      entry_title2 = 'another entry title'
      FeedClient.stub :fetch do
        feed = Feed.where(fetch_url: feed_url).first
        entry1 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title1
        entry2 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title2
        feed.entries << entry1 << entry2
        feed
      end

      # At first the user is not subscribed to the feed
      @user.feeds.where(fetch_url: feed_url).should be_blank

      @user.subscribe feed_url
      @user.feeds.where(fetch_url: feed_url).should be_present
      @user.feeds.where(fetch_url: feed_url).first.entries.count.should eq 2
      @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title1).should be_present
      @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title2).should be_present
    end

    it 'does not save in the database if there is a problem fetching the feed' do
      feed_url = 'http://a.new.feed.url.com'
      FeedClient.stub fetch: nil

      # At first the user is not subscribed to any feed
      @user.feeds.should be_blank
      @user.subscribe feed_url
      # User should still be subscribed to no feeds, and the feed should not be saved in the database
      @user.feeds.should be_blank
      Feed.where(fetch_url: feed_url).should be_blank
      Feed.where(url: feed_url).should be_blank
    end

    it 'does not save in the database if feed autodiscovery fails' do
      feed_url = 'http://a.new.feed.url.com'
      FeedClient.stub(:fetch).and_raise FeedAutodiscoveryError.new

      # At first the user is not subscribed to any feed
      @user.feeds.should be_blank
      expect {@user.subscribe feed_url}.to raise_error FeedAutodiscoveryError
      # User should still be subscribed to no feeds, and the feed should not be saved in the database
      @user.feeds.should be_blank
      Feed.where(fetch_url: feed_url).should be_blank
      Feed.where(url: feed_url).should be_blank
    end

    it 'returns false if it cannot fetch the feed' do
      feed_url = 'http://a.new.feed.url.com'
      FeedClient.stub fetch: nil

      # At first the user is not subscribed to any feed
      success = @user.subscribe feed_url
      success.should be_false
    end
  end

end
