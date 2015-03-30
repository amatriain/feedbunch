require 'rails_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
  end

  context 'enqueue a job to subscribe to a feed' do

    it 'enqueues a job to subscribe feed' do
      expect(SubscribeUserWorker.jobs.size).to eq 0

      @user.enqueue_subscribe_job @feed.fetch_url

      expect(SubscribeUserWorker.jobs.size).to eq 1
      job = SubscribeUserWorker.jobs.first
      expect(job['class']).to eq 'SubscribeUserWorker'

      args = job['args']

      # Check the arguments passed to the job
      user_id = args[0]
      expect(user_id).to eq @user.id
      fetch_url = args[1]
      expect(fetch_url).to eq @feed.fetch_url

      # Check that the job state instance passed to the job is correct
      job_state_id = args[2]
      job_state = SubscribeJobState.find job_state_id
      expect(job_state.user_id).to eq @user.id
      expect(job_state.fetch_url).to eq @feed.fetch_url
      expect(job_state.state).to eq SubscribeJobState::RUNNING
    end

    it 'enqueues a job to subscribe feed with internationalized url' do
      @feed.update fetch_url: 'http://www.gewürzrevolver.de'

      expect(SubscribeUserWorker.jobs.size).to eq 0

      @user.enqueue_subscribe_job @feed.fetch_url

      expect(SubscribeUserWorker.jobs.size).to eq 1
      job = SubscribeUserWorker.jobs.first
      expect(job['class']).to eq 'SubscribeUserWorker'

      args = job['args']

      # Check the arguments passed to the job
      user_id = args[0]
      expect(user_id).to eq @user.id
      fetch_url = args[1]
      expect(fetch_url).to eq @feed.fetch_url

      # Check that the job state instance passed to the job is correct
      job_state_id = args[2]
      job_state = SubscribeJobState.find job_state_id
      expect(job_state.user_id).to eq @user.id
      expect(job_state.fetch_url).to eq @feed.fetch_url
      expect(job_state.state).to eq SubscribeJobState::RUNNING
    end

    it 'creates a subscribe_job_state with state RUNNING' do
      expect(SubscribeJobState.count).to eq 0

      @user.enqueue_subscribe_job @feed.fetch_url

      expect(SubscribeJobState.count).to eq 1
      job_state = SubscribeJobState.first
      expect(job_state.user_id).to eq @user.id
      expect(job_state.fetch_url).to eq @feed.fetch_url
      expect(job_state.state).to eq RefreshFeedJobState::RUNNING
    end

    it 'does not enqueue job if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url

      expect(SubscribeUserWorker.jobs.size).to eq 0
      @user.enqueue_subscribe_job @feed.fetch_url
      expect(SubscribeUserWorker.jobs.size).to eq 0
    end

    it 'sets subscribe_job_state to state SUCCESS if the user is already subscribed to the feed' do
      @user.subscribe @feed.fetch_url

      @user.enqueue_subscribe_job @feed.fetch_url

      job_state = SubscribeJobState.first
      expect(job_state.user_id).to eq @user.id
      expect(job_state.fetch_url).to eq @feed.fetch_url
      expect(job_state.state).to eq RefreshFeedJobState::SUCCESS
    end

    context 'blacklisted url' do

      before :each do
        @blacklisted_url = 'some.aede.bastard.com'
        @blacklisted_host = Addressable::URI.parse("http://#{@blacklisted_url}").host
        Rails.application.config.hosts_blacklist = [@blacklisted_host]
      end

      it 'does not enqueue job and sets state to ERROR if url matches exactly blacklisted url' do
        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0
        expect{@user.enqueue_subscribe_job @blacklisted_url}.to raise_error BlacklistedUrlError
        expect(SubscribeUserWorker.jobs.size).to eq 0

        # a job state ERROR is created
        job_state = SubscribeJobState.first
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq @blacklisted_url
        expect(job_state.state).to eq RefreshFeedJobState::ERROR
      end

      it 'does not enqueue job and sets state to ERROR if url is internationalized and blacklisted' do
        blacklisted_url = 'http://www.gewürzrevolver.de'
        normalized_url = Addressable::URI.parse(blacklisted_url).normalize
        blacklisted_host = normalized_url.host
        Rails.application.config.hosts_blacklist = [blacklisted_host]

        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0
        expect{@user.enqueue_subscribe_job blacklisted_url}.to raise_error BlacklistedUrlError
        expect(SubscribeUserWorker.jobs.size).to eq 0

        # a job state ERROR is created
        job_state = SubscribeJobState.first
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq blacklisted_url
        expect(job_state.state).to eq RefreshFeedJobState::ERROR
      end

      it 'does not enqueue job and sets state to ERROR if url is a subpath of blacklisted url' do
        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0
        expect{@user.enqueue_subscribe_job "http://#{@blacklisted_url}/feed.php"}.to raise_error BlacklistedUrlError
        expect(SubscribeUserWorker.jobs.size).to eq 0

        # a job state ERROR is created
        job_state = SubscribeJobState.first
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq "http://#{@blacklisted_url}/feed.php"
        expect(job_state.state).to eq RefreshFeedJobState::ERROR
      end

      it 'does not enqueue job and sets state to ERROR if url is subdomain of blacklisted url' do
        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0
        expect{@user.enqueue_subscribe_job "http://subdomain.#{@blacklisted_url}"}.to raise_error BlacklistedUrlError
        expect(SubscribeUserWorker.jobs.size).to eq 0

        # a job state ERROR is created
        job_state = SubscribeJobState.first
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq "http://subdomain.#{@blacklisted_url}"
        expect(job_state.state).to eq RefreshFeedJobState::ERROR
      end

      it 'does not enqueue job and sets state to ERROR if url is subpath and subdomain of blacklisted url' do
        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0
        expect{@user.enqueue_subscribe_job "http://subdomain.#{@blacklisted_url}/feed.php"}.to raise_error BlacklistedUrlError
        expect(SubscribeUserWorker.jobs.size).to eq 0

        # a job state ERROR is created
        job_state = SubscribeJobState.first
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq "http://subdomain.#{@blacklisted_url}/feed.php"
        expect(job_state.state).to eq RefreshFeedJobState::ERROR
      end

      it 'enqueues job and creates job state RUNNING if url host is substring but not subdomain of a blacklisted url' do
        not_blacklisted_url = "http://subdomain#{@blacklisted_url}/feed.php"

        # job is not enqueued
        expect(SubscribeUserWorker.jobs.size).to eq 0

        expect{@user.enqueue_subscribe_job not_blacklisted_url}.not_to raise_error

        expect(SubscribeUserWorker.jobs.size).to eq 1
        job = SubscribeUserWorker.jobs.first
        expect(job['class']).to eq 'SubscribeUserWorker'

        args = job['args']

        # Check the arguments passed to the job
        user_id = args[0]
        expect(user_id).to eq @user.id
        fetch_url = args[1]
        expect(fetch_url).to eq not_blacklisted_url

        # Check that the job state instance passed to the job is correct
        job_state_id = args[2]
        job_state = SubscribeJobState.find job_state_id
        expect(job_state.user_id).to eq @user.id
        expect(job_state.fetch_url).to eq not_blacklisted_url
        expect(job_state.state).to eq SubscribeJobState::RUNNING
      end
    end

  end

  context 'subscribe to feed immediately' do

    it 'does not allow subscribing to the same feed more than once' do
      @user.subscribe @feed.fetch_url
      expect {@user.subscribe @feed.fetch_url}.to raise_error
      expect(@user.feeds.count).to eq 1
      expect(@user.feeds.first).to eq @feed
    end

    it 'rejects non-valid URLs' do
      invalid_url = 'not-an-url'
      expect{@user.subscribe invalid_url}.to raise_error
      expect(@user.feeds.where(fetch_url: invalid_url)).to be_blank
      expect(@user.feeds.where(url: invalid_url)).to be_blank
    end

    it 'accepts URLs without scheme, defaults to http://' do
      url = 'xkcd.com/'
      allow(FeedClient).to receive :fetch do |feed, args|
        feed
      end

      result = @user.subscribe url

      expect(result).to be_present
      feed = @user.feeds.find_by fetch_url: "http://#{url}"
      expect(feed).to be_present
      expect(result).to eq feed
    end

    it 'accepts URLs with feed:// scheme, defaults to http://' do
      url_feed = 'feed://xkcd.com/'
      url_http = 'http://xkcd.com/'
      allow(FeedClient).to receive :fetch do |feed, args|
        feed
      end

      result = @user.subscribe url_feed

      expect(result).to be_present
      feed = @user.feeds.find_by fetch_url: url_http
      expect(feed).to be_present
      expect(result).to eq feed
    end

    it 'accepts URLs with feed: scheme, defaults to http://' do
      url_feed = 'feed:http://xkcd.com/'
      url_http = 'http://xkcd.com/'
      allow(FeedClient).to receive :fetch do |feed, args|
        feed
      end

      result = @user.subscribe url_feed

      expect(result).to be_present
      feed = @user.feeds.find_by fetch_url: url_http
      expect(feed).to be_present
      expect(result).to eq feed
    end

    it 'accepts internationalized URLs' do
      url = 'http://www.gewürzrevolver.de/'
      allow(FeedClient).to receive :fetch do |feed, args|
        feed
      end

      result = @user.subscribe url

      expect(result).to be_present
      feed = @user.feeds.find_by fetch_url: Addressable::URI.parse(url).normalize.to_s
      expect(feed).to be_present
      expect(result).to eq feed
    end

    it 'subscribes existing feed' do
      url = 'xkcd.com'
      existing_feed = FactoryGirl.create :feed
      allow(FeedClient).to receive :fetch do
        existing_feed
      end

      result = @user.subscribe url

      expect(result).to eq existing_feed
      expect(@user.feeds.count).to eq 1
      expect(@user.feeds).to include existing_feed
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url' do
      # User is already subscribed to the feed
      @user.subscribe @feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe @feed.fetch_url}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, fetch_url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
    end

    it 'subscribes user to feed already in the database, given its fetch_url' do
      # At first the user is not subscribed to the feed
      expect(@user.feeds.where(fetch_url: @feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe @feed.fetch_url
      expect(result).to eq @feed
      expect(@user.feeds.find_by fetch_url: @feed.fetch_url).to eq @feed
    end

    it 'subscribes user to feed already in the database, given its fetch_url with added trailing slash' do
      url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      expect(@user.feeds.where(fetch_url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_slash
      expect(result).to eq feed
      expect(@user.feeds.find_by fetch_url: feed.fetch_url).to eq feed
    end

    it 'subscribes user to feed already in the database, given its fetch_url missing a trailing slash' do
      url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      expect(@user.feeds.where(fetch_url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_no_slash
      expect(result).to eq feed
      expect(@user.feeds.find_by fetch_url: feed.fetch_url).to eq feed
    end

    it 'subscribes user to feed already in the database, given its fetch_url without uri-scheme' do
      url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, fetch_url: url
      expect(@user.feeds.where(fetch_url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_no_scheme
      expect(result).to eq feed
      expect(@user.feeds.find_by fetch_url: feed.fetch_url).to eq feed
    end

    it 'subscribes to a feed already in the database, given a website URL that through autodiscovery leads to its fetch_url' do
      # Fetching a feed returns an HTML document with feed autodiscovery
      webpage_url = 'http://www.some.webpage.url/'
      alternate_webpage_url = 'http://some.webpage.url/'
      fetch_url = 'http://some.webpage.url/feed.php'

      existing_feed = FactoryGirl.create :feed, url: webpage_url, fetch_url: fetch_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_title = 'new feed title'
      entry_title = 'some entry title'
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>http://xkcd.com</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{Time.zone.now}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      allow(RestClient).to receive :get do |url|
        if url == alternate_webpage_url
          webpage_html
        elsif url == fetch_url
          feed_xml
        end
      end

      @user.subscribe alternate_webpage_url

      expect(@user.feeds).to include existing_feed
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url' do
      # User is already subscribed to the feed
      @user.subscribe @feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe @feed.url}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url missing a trailing slash' do
      feed_url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url with an added trailing slash' do
      feed_url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe twice to a feed, given its url without URI-scheme' do
      feed_url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      feed = FactoryGirl.create :feed, url: feed_url
      # User is already subscribed to the feed
      @user.subscribe feed.fetch_url

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
    end

    it 'raises an error if user tries to subscribe to a website URL that through autodiscovery leads to a subscribed feed' do
      # Fetching a feed returns an HTML document with feed autodiscovery
      webpage_url = 'http://www.some.webpage.url/'
      alternate_webpage_url = 'http://some.webpage.url/'
      fetch_url = 'http://some.webpage.url/feed.php'

      existing_feed = FactoryGirl.create :feed, url: webpage_url, fetch_url: fetch_url
      @user.subscribe existing_feed.fetch_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_title = 'new feed title'
      entry_title = 'some entry title'
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{Time.zone.now}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      allow(RestClient).to receive :get do |url|
        if url == webpage_url || url == alternate_webpage_url
          webpage_html
        elsif url == fetch_url
          feed_xml
        end
      end

      expect{@user.subscribe alternate_webpage_url}.to raise_error AlreadySubscribedError

      expect(@user.feeds).to include existing_feed
    end

    it 'subscribes user to feed already in the database, given its url' do
      # At first the user is not subscribed to the feed
      expect(@user.feeds.where(url: @feed.url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe @feed.url
      expect(result).to eq @feed
      expect(@user.feeds.find_by url: @feed.url).to eq @feed
    end

    it 'subscribes user to feed already in the database, given its url with added trailing slash' do
      url = 'http://some.host/feed'
      url_slash = 'http://some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      expect(@user.feeds.where(url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_slash
      expect(result).to eq feed
      expect(@user.feeds.find_by url: feed.url).to eq feed
    end

    it 'subscribes user to feed already in the database, given its url missing a trailing slash' do
      url = 'http://some.host/feed/'
      url_no_slash = 'http://some.host/feed'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      expect(@user.feeds.where(url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_no_slash
      expect(result).to eq feed
      expect(@user.feeds.find_by url: feed.url).to eq feed
    end

    it 'subscribes user to feed already in the database, given its url without uri-scheme' do
      url = 'http://some.host/feed/'
      url_no_scheme = 'some.host/feed/'
      # At first the user is not subscribed to the feed
      feed = FactoryGirl.create :feed, url: url
      expect(@user.feeds.where(url: feed.fetch_url)).to be_blank

      # The feed is already in the database, no attempt to save it should happen
      expect_any_instance_of(Feed).not_to receive :save

      # Feed already should have entries in the database, no attempt to fetch it should happen
      expect(FeedClient).not_to receive :fetch

      result = @user.subscribe url_no_scheme
      expect(result).to eq feed
      expect(@user.feeds.find_by url: feed.url).to eq feed
    end

    it 'adds new feed to the database and subscribes user to it' do
      feed_url = 'http://a.new.feed.url.com/'
      entry_title1 = 'an entry title'
      entry_title2 = 'another entry title'
      allow(FeedClient).to receive :fetch do
        feed = Feed.find_by fetch_url: feed_url
        entry1 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title1
        entry2 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title2
        feed.entries << entry1 << entry2
        feed
      end

      # At first the user is not subscribed to the feed
      expect(@user.feeds.where(fetch_url: feed_url)).to be_blank

      @user.subscribe feed_url
      expect(@user.feeds.where(fetch_url: feed_url)).to be_present
      expect(@user.feeds.find_by(fetch_url: feed_url).entries.count).to eq 2
      expect(@user.feeds.find_by(fetch_url: feed_url).entries.where(title: entry_title1)).to be_present
      expect(@user.feeds.find_by(fetch_url: feed_url).entries.where(title: entry_title2)).to be_present
    end

    it 'subscribes to a feed not in the database, given the website URL' do
      # Fetching a feed returns an HTML document with feed autodiscovery
      webpage_url = 'http://some.webpage.url/'
      fetch_url = 'http://some.webpage.url/feed.php'

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_title = 'new feed title'
      entry_title = 'some entry title'
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{Time.zone.now}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      allow(RestClient).to receive :get do |url|
        if url == webpage_url
          webpage_html
        elsif url == fetch_url
          feed_xml
        end

      end

      @user.subscribe webpage_url

      expect(@user.feeds.where(url: webpage_url, fetch_url: fetch_url)).to be_present
    end

    it 'subscribes to a feed not in the database, given the website URL without scheme' do
      # Fetching a feed returns an HTML document with feed autodiscovery
      webpage_url = 'http://some.webpage.url/'
      url_no_schema = 'some.webpage.url/'
      fetch_url = 'http://some.webpage.url/feed.php'

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_title = 'new feed title'
      entry_title = 'some entry title'
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{Time.zone.now}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      allow(RestClient).to receive :get do |url|
        if url == webpage_url
          webpage_html
        elsif url == fetch_url
          feed_xml
        end

      end

      @user.subscribe url_no_schema

      expect(@user.feeds.where(url: webpage_url, fetch_url: fetch_url)).to be_present
    end

    it 'does not save in the database if there is a problem fetching the feed' do
      feed_url = 'http://a.new.feed.url.com'
      allow(FeedClient).to receive(:fetch).and_return nil

      # At first the user is not subscribed to any feed
      expect(@user.feeds).to be_blank
      @user.subscribe feed_url
      # User should still be subscribed to no feeds, and the feed should not be saved in the database
      expect(@user.feeds).to be_blank
      expect(Feed.where(fetch_url: feed_url)).to be_blank
      expect(Feed.where(url: feed_url)).to be_blank
    end

    it 'does not save in the database if feed autodiscovery fails' do
      feed_url = 'http://a.new.feed.url.com'
      allow(FeedClient).to receive(:fetch).and_raise FeedAutodiscoveryError.new

      # At first the user is not subscribed to any feed
      expect(@user.feeds).to be_blank
      expect {@user.subscribe feed_url}.to raise_error FeedAutodiscoveryError
      # User should still be subscribed to no feeds, and the feed should not be saved in the database
      expect(@user.feeds).to be_blank
      expect(Feed.where(fetch_url: feed_url)).to be_blank
      expect(Feed.where(url: feed_url)).to be_blank
    end

    it 'returns nil if it cannot fetch the feed' do
      feed_url = 'http://a.new.feed.url.com'
      allow(FeedClient).to receive(:fetch).and_return nil

      # At first the user is not subscribed to any feed
      success = @user.subscribe feed_url
      expect(success).to be_nil
    end

  end

end
