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

  context 'fetching' do

    before :each do
      @entry1 = FactoryGirl.build :entry
      @entry1.title = 'Silence'
      @entry1.url = 'http://xkcd.com/1199/'
      @entry1.summary = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      @entry1.published = 'Mon, 15 Apr 2013 04:00:00 -0000'
      @entry1.guid = 'http://xkcd.com/1199/'

      @entry2 = FactoryGirl.build :entry
      @entry2.title = 'Geologist'
      @entry2.url = 'http://xkcd.com/1198/'
      @entry2.summary = %{&lt;img src="http://imgs.xkcd.com/comics/geologist.png" title="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" alt="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;"&gt;}
      @entry2.published = 'Fri, 12 Apr 2013 04:00:00 -0000'
      @entry2.guid = 'http://xkcd.com/1198/'

      @http_client = double 'restclient'
      @http_client.stub :get
      @feed.http_client = @http_client
    end

    it 'downloads the feed XML' do
      @http_client.should_receive(:get).with @feed.fetch_url
      @feed.fetch
    end

    it 'fetches the right items from an RSS 2.0 feed' do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>xkcd.com</title>
    <link>http://xkcd.com/</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <pubDate>#{@entry2.published}</pubDate>
      <guid>#{@entry2.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML

      @http_client.stub get: feed_xml

      @feed.fetch
      @feed.entries.count.should eq 2
      
      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.content.should eq @entry1.content
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid

      entry2 = @feed.entries[1]
      entry2.title.should eq @entry2.title
      entry2.url.should eq @entry2.url
      entry2.author.should eq @entry2.author
      entry2.content.should eq @entry2.content
      entry2.summary.should eq CGI.unescapeHTML(@entry2.summary)
      entry2.published.should eq @entry2.published
      entry2.guid.should eq @entry2.guid
    end

    it 'fetches the right items from an Atom feed' do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>xkcd.com</title>
  <link href="http://xkcd.com/" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@entry1.title}</title>
    <link href="#{@entry1.url}" rel="alternate" />
    <updated>#{@entry1.published}</updated>
    <id>#{@entry1.guid}</id>
    <summary type="html">#{@entry1.summary}</summary>
  </entry>
  <entry>
    <title>#{@entry2.title}</title>
    <link href="#{@entry2.url}" rel="alternate" />
    <updated>#{@entry2.published}</updated>
    <id>#{@entry2.guid}</id>
    <summary type="html">#{@entry2.summary}</summary>
  </entry>
</feed>
FEED_XML

      @http_client.stub get: feed_xml

      @feed.fetch
      @feed.entries.count.should eq 2

      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.content.should eq @entry1.content
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid

      entry2 = @feed.entries[1]
      entry2.title.should eq @entry2.title
      entry2.url.should eq @entry2.url
      entry2.author.should eq @entry2.author
      entry2.content.should eq @entry2.content
      entry2.summary.should eq CGI.unescapeHTML(@entry2.summary)
      entry2.published.should eq @entry2.published
      entry2.guid.should eq @entry2.guid
    end

    it 'tries to cache data using an etag'

    it 'tries to cache data using last-modified'

    it 'updates entry if it is received again'
  end
end
