require 'spec_helper'

describe FeedClient do
  before :each do
    @feed = FactoryGirl.create :feed, title: 'Some feed title', url: 'http://some.feed.com'

    @feed_title = 'xkcd.com'
    @feed_url = 'http://xkcd.com/'

    @entry1 = FactoryGirl.build :entry
    @entry1.title = 'Silence'
    @entry1.url = 'http://xkcd.com/1199/'
    @entry1.summary = %{&lt;p&gt;All music is just performances of 4'33" in studios where another band happened to be playing at the time.&lt;/p&gt;}
    @entry1.published = 'Mon, 15 Apr 2013 04:00:00 -0000'
    @entry1.guid = 'http://xkcd.com/1199/'

    @entry2 = FactoryGirl.build :entry
    @entry2.title = 'Geologist'
    @entry2.url = 'http://xkcd.com/1198/'
    @entry2.summary = %{&lt;p&gt;'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.';&lt;/p&gt;}
    @entry2.published = 'Fri, 12 Apr 2013 04:00:00 -0000'
    @entry2.guid = 'http://xkcd.com/1198/'
  end

  it 'downloads the feed XML and raises an error if response is empty' do
    RestClient.should_receive(:get).with @feed.fetch_url, anything
    expect{FeedClient.fetch @feed}.to raise_error EmptyResponseError
  end

  context 'generic feed autodiscovery' do

    it 'updates fetch_url of the feed with autodiscovery full URL' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers:({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      RestClient.stub :get do |url|
        if url==feed_url
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      @feed.fetch_url.should_not eq feed_url
      FeedClient.fetch @feed, true
      @feed.reload
      @feed.fetch_url.should eq feed_url
    end

    it 'updates fetch_url of the feed with autodiscovery relative URL' do
      feed_fetch_url = 'http://webpage.com/feed'
      feed_path = '/feed'
      feed_url = 'http://webpage.com'
      feed = FactoryGirl.create :feed, title: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_path}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      RestClient.stub :get do |url|
        if url==feed_fetch_url
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      feed.fetch_url.should_not eq feed_fetch_url
      FeedClient.fetch feed, true
      feed.reload
      feed.fetch_url.should eq feed_fetch_url
    end

    it 'fetches feed' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@entry1.title}</title>
    <link href="#{@entry1.url}" rel="alternate" />
    <updated>#{@entry1.published}</updated>
    <id>#{@entry1.guid}</id>
    <summary type="html">#{@entry1.summary}</summary>
  </entry>
</feed>
FEED_XML
      feed_xml.stub headers: {}

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      RestClient.stub :get do |url|
        if url==feed_url
          feed_xml
        else
          webpage_html
        end
      end

      @feed.entries.should be_blank
      FeedClient.fetch @feed, true
      @feed.entries.count.should eq 1
      @feed.entries.where(guid: @entry1.guid).should be_present
    end

    it 'detects that autodiscovered feed is already in the database' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@entry1.title}</title>
    <link href="#{@entry1.url}" rel="alternate" />
    <updated>#{@entry1.published}</updated>
    <id>#{@entry1.guid}</id>
    <summary type="html">#{@entry1.summary}</summary>
  </entry>
</feed>
FEED_XML
      feed_xml.stub headers: {}

      old_feed = FactoryGirl.create :feed, fetch_url: feed_url
      new_feed = FactoryGirl.create :feed

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      RestClient.stub :get do |url|
        if url==feed_url
          feed_xml
        elsif url==new_feed.fetch_url
          webpage_html
        end
      end

      old_feed.entries.should be_blank

      FeedClient.fetch new_feed, true

      # When performing autodiscovery, FeedClient should realise that there is another feed in the database with
      # the autodiscovered fetch_url; it should delete the "new" feed and instead fetch and return the "old" one
      old_feed.entries.count.should eq 1
      old_feed.entries.where(guid: @entry1.guid).should be_present
      Feed.exists?(id: new_feed).should be false
    end

    it 'uses first feed available for autodiscovery' do
      rss_url = 'http://webpage.com/rss'
      atom_url = 'http://webpage.com/atom'
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_url}">
  <link rel="alternate" type="application/atom+xml" href="#{atom_url}">
  <link rel="alternate" type="application/rss+xml" href="#{rss_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      webpage_url = @feed.fetch_url
      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      RestClient.stub :get do |url|
        if url==webpage_url
          webpage_html
        else
          raise RestClient::NotModified.new

        end
      end

      @feed.fetch_url.should_not eq feed_url
      FeedClient.fetch @feed, true
      @feed.reload
      @feed.fetch_url.should eq feed_url
    end
    
  end

  context 'caching' do

    before :each do
      @feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
</feed>
FEED_XML

      @etag = "\"3648649162\""
      @last_modified = "Wed, 12 Jun 2013 04:00:06 GMT"
      @user_agent = Feedbunch::Application.config.user_agent
      @headers = {etag: @etag, last_modified: @last_modified, user_agent: @user_agent}
      @feed_xml.stub(:headers).and_return @headers
      RestClient.stub(:get).and_return @feed_xml
    end

    it 'saves etag and last-modified headers if they are in the response' do
      FeedClient.fetch @feed
      @feed.reload
      @feed.etag.should eq @etag
      @feed.last_modified.to_i.should eq @last_modified.to_i
    end

    it 'sets etag to nil in the database if the header is not present' do
      @feed = FactoryGirl.create :feed, etag:'some_etag'
      @feed.etag.should_not be_nil
      @headers = {last_modified: @last_modified}
      @feed_xml.stub(:headers).and_return @headers

      FeedClient.fetch @feed
      @feed.reload
      @feed.etag.should be_nil
    end

    it 'sets last-modified to nil in the database if the header is not present' do
      @feed = FactoryGirl.create :feed, last_modified: Time.zone.now
      @feed.last_modified.should_not be_nil
      @headers = {etag: @etag}
      @feed_xml.stub(:headers).and_return @headers

      FeedClient.fetch @feed
      @feed.reload
      @feed.last_modified.should be_nil
    end

    it 'tries to cache data using an etag' do
      @headers = {etag: @etag}
      @feed_xml.stub(:headers).and_return @headers
      # Fetch the feed a first time, so the etag is saved
      FeedClient.fetch @feed

      # Next time the feed is fetched, the etag from the last time will be sent in the if-none-match header
      @feed.reload
      RestClient.should_receive(:get).with @feed.fetch_url,
                                           {if_none_match: @feed.etag, user_agent: @user_agent}
      FeedClient.fetch @feed
    end

    it 'tries to cache data using last-modified' do
      @headers = {last_modified: @last_modified}
      @feed_xml.stub(:headers).and_return @headers
      # Fetch the feed a first time, so the last-modified is saved
      FeedClient.fetch @feed

      # Next time the feed is fetched, the last-modified from the last time will be sent in the if-modified-since header
      @feed.reload
      RestClient.should_receive(:get).with @feed.fetch_url,
                                           {if_modified_since: @feed.last_modified, user_agent: @user_agent}
      FeedClient.fetch @feed
    end

    it 'tries to cache data using both etag and last-modified' do
      # Fetch the feed a first time, so the last-modified is saved
      FeedClient.fetch @feed

      # Next time the feed is fetched, the last-modified from the last time will be sent in the if-modified-since header
      @feed.reload
      RestClient.should_receive(:get).with @feed.fetch_url,
                                           {if_none_match: @feed.etag,
                                            if_modified_since: @feed.last_modified,
                                            user_agent: @user_agent}
      FeedClient.fetch @feed
    end

    it 'does not raise errors if the server responds with 304-not modified' do
      RestClient.stub(:get).and_raise RestClient::NotModified.new
      expect {FeedClient.fetch @feed}.to_not raise_error
    end
  end

  context 'error handling' do

    it 'raises error if trying to fetch from an unreachable URL' do
      RestClient.stub(:get).and_raise SocketError.new
      expect {FeedClient.fetch @feed}.to raise_error SocketError
    end

    it 'raises error if trying to fetch from a webpage that does not have feed autodiscovery enabled' do
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}
      RestClient.stub get: webpage_html

      expect {FeedClient.fetch @feed, true}.to raise_error FeedAutodiscoveryError
    end

    it 'raises error if trying to fetch from a webpage and being told not to perform autodiscovery' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}
      RestClient.stub get: webpage_html

      expect{FeedClient.fetch @feed, false}.to raise_error FeedFetchError
    end

    it 'raises error if trying to perform feed autodiscovery on a malformed webpage' do
      webpage_html = '<!DOCTYPE html><html NOT A VALID HTML AFTER ALL'
      webpage_html.stub headers: {}
      RestClient.stub get: webpage_html

      expect {FeedClient.fetch @feed, true}.to raise_error FeedAutodiscoveryError
    end

    it 'does not enter an infinite loop during autodiscovery if the feed linked is not actually a feed' do
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="http://webpage.com">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}
      RestClient.stub get: webpage_html

      RestClient.should_receive(:get).twice
      expect {FeedClient.fetch @feed, true}.to raise_error FeedFetchError
    end

    it 'processes entries skipping those that have errors' do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <wtf>This is not a valid entry!</wtf>
  </entry>
  <entry>
    <title>#{@entry1.title}</title>
    <link href="#{@entry1.url}" rel="alternate" />
    <updated>#{@entry1.published}</updated>
    <id>#{@entry1.guid}</id>
    <summary type="html">#{@entry1.summary}</summary>
  </entry>
</feed>
FEED_XML

      feed_xml.stub(:headers).and_return({})
      RestClient.stub get: feed_xml

      FeedClient.fetch @feed
      @feed.reload
      @feed.entries.count.should eq 1

      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid
    end
  end
end