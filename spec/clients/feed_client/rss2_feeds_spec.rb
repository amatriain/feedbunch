require 'spec_helper'

describe FeedClient do
  before :each do
    @original_feed_title = 'Some feed title'
    @original_feed_url = 'http://some.feed.com/'
    @feed = FactoryGirl.create :feed, title: @original_feed_title, url: @original_feed_url

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

  context 'RSS 2.0 feed fetching' do

    before :each do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <pubDate>#{@entry2.published}</pubDate>
      <guid>#{@entry2.guid}</guid>
    </item>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML

      feed_xml.stub(:headers).and_return {}
      RestClient.stub get: feed_xml
    end

    it 'returns true if successful' do
      success = FeedClient.fetch @feed
      success.should be_true
    end

    it 'fetches the right entries and saves them in the database' do
      FeedClient.fetch @feed
      @feed.reload
      @feed.entries.count.should eq 2

      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid

      entry2 = @feed.entries[1]
      entry2.title.should eq @entry2.title
      entry2.url.should eq @entry2.url
      entry2.author.should eq @entry2.author
      entry2.summary.should eq CGI.unescapeHTML(@entry2.summary)
      entry2.published.should eq @entry2.published
      entry2.guid.should eq @entry2.guid
    end

    it 'ignores entry if it is received again' do
      # Create an entry for feed @feed with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry_before = FactoryGirl.create :entry, feed_id: @feed.id, title: 'Original title',
                                        url: 'http://original.url.com', author: 'Original author',
                                        content: 'Original content', summary: 'Original summary',
                                        published: DateTime.iso8601('2013-01-01T00:00:00'), guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid. It will be ignored
      FeedClient.fetch @feed

      # After fetching, entry should be unchanged
      entry_after = Entry.where(guid: entry_before.guid, feed_id: entry_before.feed_id).first
      entry_after.feed_id.should eq entry_before.feed_id
      entry_after.title.should eq entry_before.title
      entry_after.url.should eq entry_before.url
      entry_after.author.should eq entry_before.author
      entry_after.summary.should eq CGI.unescapeHTML(entry_before.summary)
      entry_after.guid.should eq entry_before.guid
      entry_after.published.should eq entry_before.published
    end

    it 'saves entry if another one with the same guid but from a different feed is already in the database' do
      feed2 = FactoryGirl.create :feed
      # Create an entry for feed feed2 with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry = FactoryGirl.create :entry, feed_id: feed2.id, title: 'Original title',
                                 url: 'http://origina.url.com', author: 'Original author',
                                 content: 'Original content', summary: '<p>Original summary</p>',
                                 published: DateTime.iso8601('2013-01-01T00:00:00'),
                                 guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid but different feed. Both entries
      # should be treated as different entities.
      FeedClient.fetch @feed

      # After fetching, entry should remain untouched
      entry.reload
      entry.feed_id.should eq feed2.id
      entry.title.should eq 'Original title'
      entry.url.should eq 'http://origina.url.com'
      entry.author.should eq 'Original author'
      entry.summary.should eq '<p>Original summary</p>'
      entry.published.should eq DateTime.iso8601('2013-01-01T00:00:00')
      entry.guid.should eq @entry1.guid

      # the fetched entry should be saved in the database as well
      fetched_entry = Entry.where(guid: @entry1.guid, feed_id: @feed.id).first
      fetched_entry.feed_id.should eq @feed.id
      fetched_entry.title.should eq @entry1.title
      fetched_entry.url.should eq @entry1.url
      fetched_entry.author.should eq @entry1.author
      fetched_entry.summary.should eq CGI.unescapeHTML(@entry1.summary)
      fetched_entry.published.should eq @entry1.published
      fetched_entry.guid.should eq @entry1.guid
    end

    it 'retrieves the feed title and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      @feed.title.should eq @feed_title
    end

    it 'does not update the feed title if it is not present in the feed' do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <link>#{@feed_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <pubDate>#{@entry2.published}</pubDate>
      <guid>#{@entry2.guid}</guid>
    </item>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML
      feed_xml.stub(:headers).and_return {}
      RestClient.stub get: feed_xml

      FeedClient.fetch @feed
      @feed.reload
      @feed.title.should eq @original_feed_title
    end

    it 'retrieves the feed URL and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      @feed.url.should eq @feed_url
    end

    it 'does not update the feed URL if it is not present in the feed' do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <pubDate>#{@entry2.published}</pubDate>
      <guid>#{@entry2.guid}</guid>
    </item>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML
      feed_xml.stub(:headers).and_return {}
      RestClient.stub get: feed_xml

      FeedClient.fetch @feed
      @feed.reload
      @feed.url.should eq @original_feed_url
    end
  end

  context 'RSS 2.0 feed autodiscovery' do

    it 'updates fetch_url of the feed with autodiscovery full URL' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/rss+xml" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

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
  <link rel="alternate" type="application/rss+xml" href="#{feed_path}">
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML
      feed_xml.stub headers: {}

      # First fetch the webpage; then, when fetching the actual feed URL, return an RSS 2.0 XML with one entry
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
  </channel>
</rss>
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
      Feed.exists?(new_feed).should be_false
    end

    it 'uses first feed available for autodiscovery' do
      rss_url = 'http://webpage.com/rss'
      atom_url = 'http://webpage.com/atom'
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/rss+xml" href="#{rss_url}">
  <link rel="alternate" type="application/atom+xml" href="#{atom_url}">
  <link rel="feed" href="#{feed_url}">
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

      @feed.fetch_url.should_not eq rss_url
      FeedClient.fetch @feed, true
      @feed.reload
      @feed.fetch_url.should eq rss_url
    end

  end

end