require 'rails_helper'

describe FeedClient do

  before :each do
    @special_feed_url = 'hematocritico.tumblr.com'
    @special_feed_fetch_url = 'hematocritico.tumblr.com/rss'
    @feed = FactoryBot.create :feed, url: @special_feed_url, fetch_url: @special_feed_fetch_url

    # Reset config to empty values, no special feeds are configured
    Rails.application.config.special_feeds_handlers = {}
    Rails.application.config.special_feeds_fetchers = {}

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{@feed.fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    allow(webpage_html).to receive(:headers).and_return({})

    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed.title}</title>
  <link href="#{@feed.url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>sometitle</title>
    <link href="#{@feed.fetch_url}/entrypath" rel="alternate" />
    <updated>#{Time.zone.now}</updated>
    <id>someguid</id>
    <summary type="html">somesummary</summary>
  </entry>
</feed>
FEED_XML
    allow(feed_xml).to receive(:headers).and_return({})

    # Mock RestClient
    allow(RestClient).to receive :get do |url|
      if url==@feed.url
        webpage_html
      else
        feed_xml
      end
    end

    # Mock TumblrFeedFetcher
    allow(TumblrFeedFetcher).to receive :fetch_feed do |url|
      if url==@feed.url
        webpage_html
      else
        feed_xml
      end
    end
  end

  context 'feeds that do not match list of special feeds' do

    it 'does not use a special fetcher class' do
      expect(TumblrFeedFetcher).not_to receive :fetch_feed
      expect(RestClient).to receive :get
      FeedClient.fetch @feed
    end
  end

  context 'url matches list of special feeds' do

    before :each do
      # Configure a particular host to use a special fetcher class
      Rails.application.config.special_feeds_fetchers[@special_feed_url] = TumblrFeedFetcher
      @feed.update fetch_url: 'http://someurl'
    end

    it 'uses a special fetcher class' do
      expect(RestClient).not_to receive :get
      expect(TumblrFeedFetcher).to receive :fetch_feed
      FeedClient.fetch @feed, perform_autodiscovery: true
    end
  end

  context 'fetch_url matches list of special feeds' do

    before :each do
      # Configure a particular host to use a special fetcher class
      Rails.application.config.special_feeds_fetchers[@special_feed_url] = TumblrFeedFetcher
      @feed.update url: 'http://someurl'
    end

    it 'uses a special fetcher class' do
      expect(RestClient).not_to receive :get
      expect(TumblrFeedFetcher).to receive :fetch_feed
      FeedClient.fetch @feed
    end
  end
end