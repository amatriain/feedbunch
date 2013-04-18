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

  context 'rss' do

    before :each do
      @item1={}
      @item1[:title] = 'Silence'
      @item1[:url] = 'http://xkcd.com/1199/'
      @item1[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      @item1[:published ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
      @item1[:entry_id] = 'http://xkcd.com/1199/'

      @item2={}
      @item2[:title] = 'Geologist'
      @item2[:url] = 'http://xkcd.com/1198/'
      @item2[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/geologist.png" title="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" alt="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;"&gt;}
      @item2[:published ]= 'Fri, 12 Apr 2013 04:00:00 -0000'
      @item2[:entry_id] = 'http://xkcd.com/1198/'

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>xkcd.com</title>
    <link>http://xkcd.com/</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@item1[:title]}</title>
      <link>#{@item1[:url]}</link>
      <description>#{@item1[:summary]}</description>
      <pubDate>#{@item1[:published]}</pubDate>
      <guid>#{@item1[:entry_id]}</guid>
    </item>
    <item>
      <title>#{@item2[:title]}</title>
      <link>#{@item2[:url]}</link>
      <description>#{@item2[:summary]}</description>
      <pubDate>#{@item2[:published]}</pubDate>
      <guid>#{@item2[:entry_id]}</guid>
    </item>
  </channel>
</rss>
FEED_XML

      @http_client = double 'restclient', get: feed_xml
      @feed.http_client = @http_client
    end

    it 'downloads the feed XML' do
      @http_client.should_receive(:get).with @feed.fetch_url
      @feed.fetchEntries
    end

    it 'returns the right items' do
      items = @feed.fetchEntries
      items.size.should eq 2

      items[0].title.should eq @item1[:title]
      items[0].url.should eq @item1[:url]
      items[0].summary.should eq CGI.unescapeHTML(@item1[:summary])
      items[0].published.should eq @item1[:published]
      items[0].entry_id.should eq @item1[:entry_id]

      items[1].title.should eq @item2[:title]
      items[1].url.should eq @item2[:url]
      items[1].summary.should eq CGI.unescapeHTML(@item2[:summary])
      items[1].published.should eq @item2[:published]
      items[1].entry_id.should eq @item2[:entry_id]
    end

    it 'sanitizes items' do
      item={}
      item[:title] = 'Silence&lt;script&gt;alert("pwned!");&lt;/script&gt;'
      item[:url] = 'http://xkcd.com/1199/&lt;script&gt;alert("pwned!");&lt;/script&gt;'
      item[:summary] = %{&lt;script&gt;alert("pwned!");&lt;/script&gt;&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      item[:published ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
      item[:entry_id] = '&lt;script&gt;alert("pwned!");&lt;/script&gt;http://xkcd.com/1199/'

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>xkcd.com</title>
    <link>http://xkcd.com/</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{item[:title]}</title>
      <link>#{item[:url]}</link>
      <description>#{item[:summary]}</description>
      <pubDate>#{item[:published]}</pubDate>
      <guid>#{item[:entry_id]}</guid>
    </item>
  </channel>
</rss>
FEED_XML

      @http_client = double 'restclient', get: feed_xml
      @feed.http_client = @http_client

      sanitized_item={}
      sanitized_item[:title] = 'Silence'
      sanitized_item[:url] = 'http://xkcd.com/1199/'
      sanitized_item[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      sanitized_item[:published ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
      sanitized_item[:entry_id] = 'http://xkcd.com/1199/'

      items = @feed.fetchEntries
      feed_item = items[0]
      feed_item.title.should eq sanitized_item[:title]
      feed_item.url.should eq sanitized_item[:url]
      feed_item.summary.should eq CGI.unescapeHTML(sanitized_item[:summary])
    end

  end

  context 'atom' do

    before :each do
      @item1={}
      @item1[:title] = 'Silence'
      @item1[:url] = 'http://xkcd.com/1199/'
      @item1[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      @item1[:published ]= '2013-04-15T00:00:00Z'
      @item1[:entry_id] = 'http://xkcd.com/1199/'

      @item2={}
      @item2[:title] = 'Geologist'
      @item2[:url] = 'http://xkcd.com/1198/'
      @item2[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/geologist.png" title="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" alt="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;"&gt;}
      @item2[:published ]= '2013-04-12T00:00:00Z'
      @item2[:entry_id] = 'http://xkcd.com/1198/'

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>xkcd.com</title>
  <link href="http://xkcd.com/" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@item1[:title]}</title>
    <link href="#{@item1[:url]}" rel="alternate" />
    <updated>#{@item1[:published ]}</updated>
    <id>#{@item1[:entry_id]}</id>
    <summary type="html">#{@item1[:summary]}</summary>
  </entry>
  <entry>
    <title>#{@item2[:title]}</title>
    <link href="#{@item2[:url]}" rel="alternate" />
    <updated>#{@item2[:published ]}</updated>
    <id>#{@item2[:entry_id]}</id>
    <summary type="html">#{@item2[:summary]}</summary>
  </entry>
</feed>
FEED_XML

      @http_client = double 'restclient', get: feed_xml
      @feed.http_client = @http_client
    end

    it 'downloads the feed XML' do
      @http_client.should_receive(:get).with @feed.fetch_url
      @feed.fetchEntries
    end

    it 'returns the right items' do
      items = @feed.fetchEntries
      items.size.should eq 2

      items[0].title.should eq @item1[:title]
      items[0].url.should eq @item1[:url]
      items[0].summary.should eq CGI.unescapeHTML(@item1[:summary])
      items[0].published.should eq @item1[:published]
      items[0].entry_id.should eq @item1[:entry_id]

      items[1].title.should eq @item2[:title]
      items[1].url.should eq @item2[:url]
      items[1].summary.should eq CGI.unescapeHTML(@item2[:summary])
      items[1].published.should eq @item2[:published]
      items[1].entry_id.should eq @item2[:entry_id]
    end

    it 'sanitizes items' do
      item={}
      item[:title] = 'Silence&lt;script&gt;alert("pwned!");&lt;/script&gt;'
      item[:url] = 'http://xkcd.com/1199/&lt;script&gt;alert(quot;pwned!quot;);&lt;/script&gt;'
      item[:summary] = %{&lt;script&gt;alert("pwned!");&lt;/script&gt;&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      item[:published ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
      item[:entry_id] = '&lt;script&gt;alert("pwned!");&lt;/script&gt;http://xkcd.com/1199/'

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>xkcd.com</title>
  <link href="http://xkcd.com/" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{item[:title]}</title>
    <link href="#{item[:url]}" rel="alternate" />
    <updated>#{item[:published ]}</updated>
    <id>#{item[:entry_id]}</id>
    <summary type="html">#{item[:summary]}</summary>
  </entry>
</feed>
FEED_XML

      @http_client = double 'restclient', get: feed_xml
      @feed.http_client = @http_client

      sanitized_item={}
      sanitized_item[:title] = 'Silence'
      sanitized_item[:url] = 'http://xkcd.com/1199/'
      sanitized_item[:summary] = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
      sanitized_item[:published ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
      sanitized_item[:entry_id] = 'http://xkcd.com/1199/'

      items = @feed.fetchEntries
      feed_item = items[0]
      feed_item.title.should eq sanitized_item[:title]
      feed_item.url.should eq sanitized_item[:url]
      feed_item.summary.should eq CGI.unescapeHTML(sanitized_item[:summary])
    end

  end
end
