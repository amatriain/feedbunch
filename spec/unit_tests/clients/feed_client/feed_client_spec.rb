require 'rails_helper'

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
    expect(RestClient).to receive(:get).with @feed.fetch_url, anything
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
      allow(webpage_html).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url==feed_url
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      expect(@feed.fetch_url).not_to eq feed_url
      FeedClient.fetch @feed, perform_autodiscovery: true
      @feed.reload
      expect(@feed.fetch_url).to eq feed_url
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
      allow(webpage_html).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url==feed_fetch_url
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      expect(feed.fetch_url).not_to eq feed_fetch_url
      FeedClient.fetch feed, perform_autodiscovery: true
      feed.reload
      expect(feed.fetch_url).to eq feed_fetch_url
    end

    it 'uses http:// for autodiscovered protocol relative URL' do
      feed_fetch_url_relative = '//webpage.com/feed'
      feed_fetch_url_absolute = 'http://webpage.com/feed'
      feed_url = 'http://webpage.com'
      feed = FactoryGirl.create :feed, title: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_fetch_url_relative}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url==feed_fetch_url_absolute
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      expect(feed.fetch_url).not_to eq feed_fetch_url_absolute
      FeedClient.fetch feed, perform_autodiscovery: true
      feed.reload
      expect(feed.fetch_url).to eq feed_fetch_url_absolute
    end

    it 'uses https:// for autodiscovered protocol relative URL' do
      feed_fetch_url_relative = '//webpage.com/feed/'
      feed_fetch_url_absolute = 'https://webpage.com/feed/'
      feed_url = 'https://webpage.com'
      feed = FactoryGirl.create :feed, title: feed_url, url: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{feed_fetch_url_relative}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url==feed_fetch_url_absolute
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      expect(feed.fetch_url).not_to eq feed_fetch_url_absolute
      FeedClient.fetch feed, perform_autodiscovery: true
      feed.reload
      expect(feed.fetch_url).to eq feed_fetch_url_absolute
    end

    it 'autodiscovers from internationalized URL' do
      feed_url = 'http://www.gewürzrevolver.de'
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
      allow(webpage_html).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url == Addressable::URI.parse(feed_url).normalize.to_s
          raise RestClient::NotModified.new
        else
          webpage_html
        end
      end

      expect(@feed.fetch_url).not_to eq feed_url
      FeedClient.fetch @feed, perform_autodiscovery: true
      @feed.reload
      expect(@feed.fetch_url).to eq Addressable::URI.parse(feed_url).normalize.to_s
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
      allow(webpage_html).to receive(:headers).and_return({})

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
      allow(feed_xml).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      allow(RestClient).to receive :get do |url|
        if url==feed_url
          feed_xml
        else
          webpage_html
        end
      end

      expect(@feed.entries).to be_blank
      FeedClient.fetch @feed, perform_autodiscovery: true
      expect(@feed.entries.count).to eq 1
      expect(@feed.entries.where(guid: @entry1.guid)).to be_present
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
      allow(webpage_html).to receive(:headers).and_return({})

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
      allow(feed_xml).to receive(:headers).and_return({})

      old_feed = FactoryGirl.create :feed, fetch_url: feed_url
      new_feed = FactoryGirl.create :feed

      # user is subscribed to the feed being updated
      user = FactoryGirl.create :user
      user.subscribe new_feed.fetch_url

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      allow(RestClient).to receive :get do |url|
        if url==feed_url
          feed_xml
        elsif url==new_feed.url
          webpage_html
        end
      end

      expect(old_feed.entries).to be_blank
      expect(old_feed.users).to be_blank
      expect(new_feed.users.count).to eq 1
      expect(new_feed.users).to include user

      FeedClient.fetch new_feed, perform_autodiscovery: true

      # When performing autodiscovery, FeedClient should realise that there is another feed in the database with
      # the autodiscovered fetch_url; it should delete the "new" feed and instead fetch and return the "old" one.
      # Any users that were subscribed to the "new" feed should be subscribed to the "old" one now.
      expect(old_feed.reload.entries.count).to eq 1
      expect(old_feed.entries.where(guid: @entry1.guid)).to be_present
      expect(Feed.exists? new_feed.id).to be false
      expect(old_feed.users.count).to eq 1
      expect(old_feed.users).to include user
    end

    it 'autodiscovers already existing feed from internationalized URL' do
      feed_url = 'http://www.gewürzrevolver.de/'
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
      allow(webpage_html).to receive(:headers).and_return({})

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
      allow(feed_xml).to receive(:headers).and_return({})

      old_feed = FactoryGirl.create :feed, fetch_url: feed_url
      new_feed = FactoryGirl.create :feed

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      allow(RestClient).to receive :get do |url|
        if url == Addressable::URI.parse(feed_url).normalize.to_s
          feed_xml
        elsif url == new_feed.url
          webpage_html
        end
      end

      expect(old_feed.entries).to be_blank

      FeedClient.fetch new_feed, perform_autodiscovery: true

      # When performing autodiscovery, FeedClient should realise that there is another feed in the database with
      # the autodiscovered fetch_url; it should delete the "new" feed and instead fetch and return the "old" one
      expect(old_feed.entries.count).to eq 1
      expect(old_feed.entries.where(guid: @entry1.guid)).to be_present
      expect(Feed.exists? new_feed.id).to be false
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
      allow(webpage_html).to receive(:headers).and_return({})

      webpage_url = @feed.url
      # First fetch the webpage; then, when fetching the actual feed URL, simulate receiving a 304-Not Modified
      allow(RestClient).to receive :get do |url|
        if url==webpage_url
          webpage_html
        else
          raise RestClient::NotModified.new

        end
      end

      expect(@feed.fetch_url).not_to eq feed_url
      FeedClient.fetch @feed, perform_autodiscovery: true
      @feed.reload
      expect(@feed.fetch_url).to eq feed_url
    end
    
  end

  context 'error handling' do

    it 'raises error if trying to fetch from an unreachable URL' do
      allow(RestClient).to receive(:get).and_raise SocketError.new
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
      allow(webpage_html).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return webpage_html

      expect {FeedClient.fetch @feed, perform_autodiscovery: true}.to raise_error FeedAutodiscoveryError
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
      allow(webpage_html).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return webpage_html

      expect{FeedClient.fetch @feed, perform_autodiscovery: false}.to raise_error FeedFetchError
    end

    it 'raises error if trying to perform feed autodiscovery on a malformed webpage' do
      webpage_html = '<!DOCTYPE html><html NOT A VALID HTML AFTER ALL'
      allow(webpage_html).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return webpage_html

      expect {FeedClient.fetch @feed, perform_autodiscovery: true}.to raise_error FeedAutodiscoveryError
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
      allow(webpage_html).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return webpage_html

      expect(RestClient).to receive(:get).twice
      expect {FeedClient.fetch @feed, perform_autodiscovery: true}.to raise_error FeedFetchError
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

      allow(feed_xml).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return feed_xml

      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.entries.count).to eq 1

      entry1 = @feed.entries[0]
      expect(entry1.title).to eq @entry1.title
      expect(entry1.url).to eq @entry1.url
      expect(entry1.author).to eq @entry1.author
      expect(entry1.summary).to eq CGI.unescapeHTML(@entry1.summary)
      expect(entry1.published).to eq @entry1.published
      expect(entry1.guid).to eq @entry1.guid
    end
  end
end