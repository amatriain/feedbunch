require 'spec_helper'

describe Feed do
  before :each do
    @item1={}
    @item1[:title] = 'Silence'
    @item1[:link] = 'http://xkcd.com/1199/'
    @item1[:description] = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." /&gt;}
    @item1[:pubDate ]= 'Mon, 15 Apr 2013 04:00:00 -0000'
    @item1[:guid] = 'http://xkcd.com/1199/'

    @item2={}
    @item2[:title] = 'Geologist'
    @item2[:link] = 'http://xkcd.com/1198/'
    @item2[:description] = %{&lt;img src="http://imgs.xkcd.com/comics/geologist.png" title="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" alt="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" /&gt;}
    @item2[:pubDate ]= 'Fri, 12 Apr 2013 04:00:00 -0000'
    @item2[:guid] = 'http://xkcd.com/1198/'

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
      <link>#{@item1[:link]}</link>
      <description>#{@item1[:description]}</description>
      <pubDate>#{@item1[:pubDate]}</pubDate>
      <guid>#{@item1[:guid]}</guid>
    </item>
    <item>
      <title>#{@item2[:title]}</title>
      <link>#{@item2[:link]}</link>
      <description>#{@item2[:description]}</description>
      <pubDate>#{@item2[:pubDate]}</pubDate>
      <guid>#{@item2[:guid]}</guid>
    </item>
  </channel>
</rss>
FEED_XML

    @feed = FactoryGirl.create :feed
    @feed.stub(:open).and_return feed_xml
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

  context 'validations' do
    it 'accepts valid URLs' do
      @feed.url = 'http://www.xkcd.com/rss.xml'
      @feed.valid?.should be_true
    end

    it 'does not accept invalid URLs' do
      @feed.url = 'invalid_url'
      @feed.valid?.should be_false
    end

    it 'does not accept an empty URL' do
      @feed.url = ''
      @feed.valid?.should be_false
      @feed.url = nil
      @feed.valid?.should be_false
    end

    it 'does not accept an empty title' do
      @feed.title = ''
      @feed.valid?.should be_false
      @feed.title = nil
      @feed.valid?.should be_false
    end

    it 'does not accept duplicate URLs' do
      feed_dupe = FactoryGirl.build :feed, url: @feed.url
      feed_dupe.valid?.should be_false
    end
  end

  context 'rss' do

    it 'downloads the feed XML' do
      @feed.should_receive(:open)
      @feed.items
    end

    it 'returns the right items' do
      items = @feed.items
      items.size.should eq 2

      items[0].title.should eq @item1[:title]
      items[0].link.should eq @item1[:link]
      items[0].description.should eq CGI.unescapeHTML(@item1[:description])
      items[0].pubDate.should eq @item1[:pubDate]
      items[0].guid.content.should eq @item1[:guid]

      items[1].title.should eq @item2[:title]
      items[1].link.should eq @item2[:link]
      items[1].description.should eq CGI.unescapeHTML(@item2[:description])
      items[1].pubDate.should eq @item2[:pubDate]
      items[1].guid.content.should eq @item2[:guid]
    end

  end
end
