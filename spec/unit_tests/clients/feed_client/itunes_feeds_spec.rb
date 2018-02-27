require 'rails_helper'

describe FeedClient do

  before :each do
    @feed = FactoryBot.create :feed, title: 'Some feed title', url: 'http://some.feed.com'

    @feed_title = 'Menéame: publicadas'
    @feed_url = 'http://www.meneame.net/'

    @entry1 = FactoryBot.build :entry
    @entry1.title = 'Los correos secretos de Caja Madrid: así celebró Blesa el \'éxito\' de las preferentes'
    @entry1.url = 'http://meneame.feedsportal.com/c/34737/f/639540/s/34adc456/sc/36/l/0L0Smeneame0Bnet0Cstory0Ccorreos0Esecretos0Ecaja0Emadrid0Easi0Ecelebro0Eblesa0Eexito0Epreferentes/story01.htm'
    @entry1.summary = %{&lt;p&gt;Como una fiesta financiera, como un pelotazo empresarial, como un nuevo récord. Así vivió Miguel Blesa, entonces presidente de Caja Madrid, la millonaria emisión de preferentes en 2009, un producto financiero que atrapó a miles de clientes de la entidad y volatilizó sus ahorros. Varios correos del mejor amigo de Aznar en la banca, a los que ha tenido acceso eldiario.es, describen el ambiente de euforia sin vértigo en aquellos días de emisiones millonarias.&lt;/p&gt;}
    @entry1.published = 'Wed, 11 Dec 2013 07:20:04 GMT'
    @entry1.guid = 'http://www.meneame.net/story/correos-secretos-caja-madrid-asi-celebro-blesa-exito-preferentes'

    @entry2 = FactoryBot.build :entry
    @entry2.title = '“La mafia despilfarradora y corrupta no está dispuesta a tocar nada que afecte a su chiringuito”'
    @entry2.url = 'http://meneame.feedsportal.com/c/34737/f/639540/s/34ab2350/sc/36/l/0L0Smeneame0Bnet0Cstory0Cmafia0Edespilfarradora0Ecorrupta0Eno0Eesta0Edispuesta0Etocar0Enada/story01.htm'
    @entry2.summary = %{&lt;p&gt;En EE.UU baja el paro, Gran Bretaña crece ya al 5% y el resto del mundo trabaja sin desmayo para salir de la crisis, pero España sigue empantanada en el fango de la corrupción, el despilfarro público y su consecuencia directa: paro, exilio laboral, miseria y hasta hambre física. Eurostat desmiente las cifras oficiales: sigue habiendo más de 6 millones de parados a causa del creciente gasto de políticos y autonomías.&lt;/p&gt;}
    @entry2.published = 'Wed, 11 Dec 2013 00:30:04 GMT'
    @entry2.guid = 'http://www.meneame.net/story/mafia-despilfarradora-corrupta-no-esta-dispuesta-tocar-nada'
  end

  context 'Itunes feed fetching' do

    before :each do
      feed_xml = <<FEED_XML
<?xml version='1.0' encoding='UTF-8'?>
<?xml-stylesheet type='text/xsl' href='http://meneame.feedsportal.com/xsl/es/rss.xsl'?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:wfw="http://wellformedweb.org/CommentAPI/" xmlns:media="http://search.yahoo.com/mrss/" xmlns:meneame="http://meneame.net/faq-es.php" version="2.0">
  <channel>
    <atom:link href="http://www.meneame.net/rss2.php" rel="self" type="application/rss+xml"/>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>Sitio colaborativo de publicación y comunicación entre blogs</description>
    <language>es</language>
    <pubDate>Wed, 11 Dec 2013 07:20:04 GMT</pubDate>
    <lastBuildDate>Wed, 11 Dec 2013 07:20:04 GMT</lastBuildDate>
    <ttl>10</ttl>
    <image>
      <title>Menéame: publicadas</title>
      <url>http://mnmstatic.net/img/mnm/eli-rss.png</url>
      <link>http://www.meneame.net</link>
    </image>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <category domain="">estafa</category>
      <category domain="">caja madrid</category>
      <category domain="">preferentes</category>
      <category domain="">sociedad</category>
      <category domain="">blesa</category>
      <pubDate>#{@entry2.published}</pubDate>
      <comments>http://www.meneame.net/story/correos-secretos-caja-madrid-asi-celebro-blesa-exito-preferentes</comments>
      <guid isPermaLink="false">#{@entry2.guid}</guid>
      <wfw:commentRss>http://www.meneame.net/comments_rss2.php?id=2074219</wfw:commentRss>
      <dc:creator>Arc</dc:creator>
      <media:thumbnail url="http://mnmstatic.net/cache/1f/a6/thumb-2074219.jpg" width="60" height="60"/>
      <meneame:link_id>2074219</meneame:link_id>
      <meneame:status>published</meneame:status>
      <meneame:user>Arc</meneame:user>
      <meneame:votes>65</meneame:votes>
      <meneame:negatives>0</meneame:negatives>
      <meneame:karma>616</meneame:karma>
      <meneame:comments>9</meneame:comments>
      <meneame:url>http://www.eldiario.es/economia/Blesa-negocio-preferentes-Caja-Madrid_0_205430051.html</meneame:url>
    </item>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <category domain="">corrupta</category>
      <category domain="">mafia</category>
      <category domain="">política</category>
      <category domain="">chiringuito</category>
      <category domain="">ee.uu</category>
      <pubDate>#{@entry1.published}</pubDate>
      <comments>http://www.meneame.net/story/mafia-despilfarradora-corrupta-no-esta-dispuesta-tocar-nada</comments>
      <guid isPermaLink="false">#{@entry1.guid}</guid>
      <wfw:commentRss>http://www.meneame.net/comments_rss2.php?id=2073682</wfw:commentRss>
      <dc:creator>inconformistadesdeel67</dc:creator>
      <media:thumbnail url="http://mnmstatic.net/cache/1f/a4/thumb-2073682.jpg" width="60" height="60"/>
      <meneame:link_id>2073682</meneame:link_id>
      <meneame:status>published</meneame:status>
      <meneame:user>inconformistadesdeel67</meneame:user>
      <meneame:votes>116</meneame:votes>
      <meneame:negatives>11</meneame:negatives>
      <meneame:karma>666</meneame:karma>
      <meneame:comments>15</meneame:comments>
      <meneame:url>http://www.espiaenelcongreso.com/2013/12/09/la-mafia-despilfarradora-y-corrupta-no-esta-dispuesta-a-tocar-nada-que-afecte-a-su-chiringuito/</meneame:url>
    </item>
  </channel>
</rss>
FEED_XML

      allow(feed_xml).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return feed_xml
    end

    it 'returns the feed if successful' do
      feed = FeedClient.fetch @feed
      expect(feed).to be @feed
    end

    it 'fetches the right entries and saves them in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.entries.count).to eq 2

      entry1 = @feed.entries[0]
      expect(entry1.title).to eq @entry1.title
      expect(entry1.url).to eq @entry1.url
      expect(entry1.author).to eq @entry1.author
      expect(entry1.summary).to eq CGI.unescapeHTML(@entry1.summary)
      expect(entry1.published).to eq @entry1.published
      expect(entry1.guid).to eq @entry1.guid

      entry2 = @feed.entries[1]
      expect(entry2.title).to eq @entry2.title
      expect(entry2.url).to eq @entry2.url
      expect(entry2.author).to eq @entry2.author
      expect(entry2.summary).to eq CGI.unescapeHTML(@entry2.summary)
      expect(entry2.published).to eq @entry2.published
      expect(entry2.guid).to eq @entry2.guid
    end

    it 'ignores entry if it is received again' do
      # Create an entry for feed @feed with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry_before = FactoryBot.create :entry, feed_id: @feed.id, title: 'Original title',
                                        url: 'http://original.url.com', author: 'Original author',
                                        content: 'Original content', summary: 'Original summary',
                                        published: Time.zone.parse('2013-01-01T00:00:00'), guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid. It will be ignored
      FeedClient.fetch @feed

      # After fetching, entry should be unchanged
      entry_after = Entry.find_by guid: entry_before.guid, feed_id: entry_before.feed_id
      expect(entry_after.feed_id).to eq entry_before.feed_id
      expect(entry_after.title).to eq entry_before.title
      expect(entry_after.url).to eq entry_before.url
      expect(entry_after.author).to eq entry_before.author
      expect(entry_after.summary).to eq CGI.unescapeHTML(entry_before.summary)
      expect(entry_after.guid).to eq entry_before.guid
      expect(entry_after.published).to eq entry_before.published
    end

    it 'saves entry if another one with the same guid but from a different feed is already in the database' do
      feed2 = FactoryBot.create :feed
      # Create an entry for feed feed2 with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry = FactoryBot.create :entry, feed_id: feed2.id, title: 'Original title',
                                 url: 'http://original.url.com/', author: 'Original author',
                                 content: 'Original content', summary: '<p>Original summary</p>',
                                 published: Time.zone.parse('2013-01-01T00:00:00'),
                                 guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid but different feed. Both entries
      # should be treated as different entities.
      FeedClient.fetch @feed

      # After fetching, entry should remain untouched
      entry.reload
      expect(entry.feed_id).to eq feed2.id
      expect(entry.title).to eq 'Original title'
      expect(entry.url).to eq 'http://original.url.com/'
      expect(entry.author).to eq 'Original author'
      expect(entry.summary).to eq '<p>Original summary</p>'
      expect(entry.published).to eq Time.zone.parse('2013-01-01T00:00:00')
      expect(entry.guid).to eq @entry1.guid

      # the fetched entry should be saved in the database as well
      fetched_entry = Entry.find_by guid: @entry1.guid, feed_id: @feed.id
      expect(fetched_entry.feed_id).to eq @feed.id
      expect(fetched_entry.title).to eq @entry1.title
      expect(fetched_entry.url).to eq @entry1.url
      expect(fetched_entry.author).to eq @entry1.author
      expect(fetched_entry.summary).to eq CGI.unescapeHTML(@entry1.summary)
      expect(fetched_entry.published).to eq @entry1.published
      expect(fetched_entry.guid).to eq @entry1.guid
    end

    it 'retrieves the feed title and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.title).to eq @feed_title
    end

    it 'retrieves the feed URL and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.url).to eq @feed_url
    end
  end

  context 'Itunes feed with enclosure (e.g. podcast)' do

    before :each do
      @feed = FactoryBot.create :feed, title: 'Some feed title', url: 'http://some.feed.com'
      @feed_title = 'Planet Money'
      @feed_url = 'http://www.npr.org/planetmoney'

      @entry1 = FactoryBot.build :entry
      @entry1.title = '#474: The North Korea Files'
      @entry1.url = 'https://play.podtrac.com/npr-510289/npr.mc.tritondigital.com/NPR_510289/media/anon.npr-podcasts/podcast/510289/365828514/npr_365828514.mp3?orgId=1&d=1495&p=510289&story=365828514&t=podcast&e=365828514&ft=pod&f=510289'
      @entry1.summary = %{&lt;p&gt;Note: Today's show is a rerun. It originally ran in July 2013. U.S. citizens who want to buy stuff from North Korea have to write a letter to the U.S. government asking for special permission. As regular listeners know, we're sort of obsessed with North Korea. So we decided to try to get those letters. We filed a Freedom of Information Act request. And we got a stack of heavily redacted letters. On today's show: we try to figure out who sent the letters, why they wanted to do business with North Korea, and what that tells us about the North Korean economy.&lt;/p&gt;}
      @entry1.published = 'Fri, 21 Nov 2014 21:03:42 -0500'
      @entry1.guid = 'http://podcastdownload.npr.org/anon.npr-podcasts/podcast/510289/365828514/npr_365828514.mp3'

      @entry2 = FactoryBot.build :entry
      @entry2.title = '#585: Chasing The Dread Pirate Roberts'
      @entry2.url = 'https://play.podtrac.com/npr-510289/npr.mc.tritondigital.com/NPR_510289/media/anon.npr-mp3/npr/blog/2014/11/20141125_blog_pmoney.mp3?orgId=1&d=1218&p=510289&story=432088483&t=podcast&e=432088483&ft=pod&f=510289'
      @entry2.summary = %{&lt;p&gt;Today on the show, the story of the Dread Pirate Roberts of the internet age. A man who dreamed of setting up a utopian marketplace, a place where you could buy and sell almost anything in secret. The pirate created a market with no contracts, no regulations, and really no government interference. The Dread Pirate believed in total economic freedom, but in order to make his market work, he had to do some very bad things.&lt;/p&gt;}
      @entry2.published = 'Wed, 26 Nov 2014 12:13:00 -0500'
      @entry2.guid = '7fb07b53-60b4-4b71-ae7b-09f4564498ea'

      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:npr="http://www.npr.org/rss/" xmlns:nprml="http://api.npr.org/nprml" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description><![CDATA[The economy, explained, with stories and surprises. Imagine you could call up a friend and say, "Meet me at the bar and tell me what's going on with the economy." Now imagine that's actually a fun evening. That's what we're going for at <em>Planet Money</em>. People seem to like it.]]></description>
    <copyright>2015 National Public Radio</copyright>
    <generator>NPR API RSS Generator 0.94</generator>
    <language>en</language>
    <itunes:summary><![CDATA[The economy, explained, with stories and surprises. Imagine you could call up a friend and say, "Meet me at the bar and tell me what's going on with the economy." Now imagine that's actually a fun evening. That's what we're going for at <em>Planet Money</em>. People seem to like it.]]></itunes:summary>
    <itunes:subtitle><![CDATA[The economy, explained, with stories and surprises. Imagine you could call up a friend and say, "Meet me at the bar and tell me what's going on with the economy." Now imagine that's actually a fun evening. That's what we're going for at <em>Planet Money</em>. People seem to like it.]]></itunes:subtitle>
    <itunes:author>NPR</itunes:author>
    <itunes:block>no</itunes:block>
    <itunes:owner>
      <itunes:email>podcasts@npr.org</itunes:email>
      <itunes:name>NPR</itunes:name>
    </itunes:owner>
    <itunes:category text="Business"/>
    <itunes:category text="News &amp; Politics"/>
    <itunes:category text="Business News"/>
    <itunes:image href="https://media.npr.org/assets/img/2015/12/18/planetmoney_sq-c7d1c6f957f3b7f701f8e1d5546695cebd523720.jpg?s=1400"/>
    <image>
      <url>https://media.npr.org/assets/img/2015/12/18/planetmoney_sq-c7d1c6f957f3b7f701f8e1d5546695cebd523720.jpg?s=200</url>
      <title>Planet Money</title>
      <link>http://www.npr.org/planetmoney</link>
    </image>
    <lastBuildDate>Wed, 30 Nov 2016 15:36:00 -0500</lastBuildDate>
    <item>
      <title>#{@entry2.title}</title>
      <description><![CDATA[Today on the show, the story of the Dread Pirate Roberts of the internet age. A man who dreamed of setting up a utopian marketplace, a place where you could buy and sell almost anything in secret. The pirate created a market with no contracts, no regulations, and really no government interference. The Dread Pirate believed in total economic freedom, but in order to make his market work, he had to do some very bad things.]]></description>
      <pubDate>#{@entry2.published}</pubDate>
      <copyright>2015 National Public Radio</copyright>
      <guid>#{@entry2.guid}</guid>
      <itunes:author>NPR</itunes:author>
      <itunes:summary>#{@entry2.summary}</itunes:summary>
      <itunes:subtitle><![CDATA[Today on the show, the story of the Dread Pirate Roberts of the internet age. A man who dreamed of setting up a utopian marketplace, a place where you could buy and sell almost anything in secret. The pirate created a market with no contracts, no regulations, and really no government interference. The Dread Pirate believed in total economic freedom, but in order to make his market work, he had to do some very bad things.]]></itunes:subtitle>
      <itunes:duration>1218</itunes:duration>
      <itunes:explicit>yes</itunes:explicit>
      <enclosure url="#{@entry2.url}" length="0" type="audio/mpeg"/>
    </item>
    <item>
      <title>#{@entry1.title}</title>
      <description><![CDATA[Note: Today's show is a rerun. It originally ran in July 2013. U.S. citizens who want to buy stuff from North Korea have to write a letter to the U.S. government asking for special permission. As regular listeners know, we're sort of obsessed with North Korea. So we decided to try to get those letters. We filed a Freedom of Information Act request. And we got a stack of heavily redacted letters. On today's show: we try to figure out who sent the letters, why they wanted to do business with North Korea, and what that tells us about the North Korean economy.]]></description>
      <pubDate>#{@entry1.published}</pubDate>
      <copyright>2015 National Public Radio</copyright>
      <guid>#{@entry1.guid}</guid>
      <itunes:author>NPR</itunes:author>
      <itunes:summary>#{@entry1.summary}</itunes:summary>
      <itunes:subtitle><![CDATA[Note: Today's show is a rerun. It originally ran in July 2013. U.S. citizens who want to buy stuff from North Korea have to write a letter to the U.S. government asking for special permission. As regular listeners know, we're sort of obsessed with North Korea. So we decided to try to get those letters. We filed a Freedom of Information Act request. And we got a stack of heavily redacted letters. On today's show: we try to figure out who sent the letters, why they wanted to do business with North Korea, and what that tells us about the North Korean economy.]]></itunes:subtitle>
      <itunes:duration>1495</itunes:duration>
      <itunes:explicit>no</itunes:explicit>
      <enclosure url="#{@entry1.url}" length="12032087" type="audio/mpeg"/>
    </item>
  </channel>
</rss>
FEED_XML

      allow(feed_xml).to receive(:headers).and_return({})
      allow(RestClient).to receive(:get).and_return feed_xml
    end

    it 'returns the feed if successful' do
      feed = FeedClient.fetch @feed
      expect(feed).to be @feed
    end

    it 'fetches the right entries and saves them in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.entries.count).to eq 2

      entry1 = @feed.entries[0]
      expect(entry1.title).to eq @entry1.title
      expect(entry1.url).to eq @entry1.url
      expect(entry1.author).to eq @entry1.author
      expect(entry1.summary).to eq CGI.unescapeHTML(@entry1.summary)
      expect(entry1.published).to eq @entry1.published
      expect(entry1.guid).to eq @entry1.guid

      entry2 = @feed.entries[1]
      expect(entry2.title).to eq @entry2.title
      expect(entry2.url).to eq @entry2.url
      expect(entry2.author).to eq @entry2.author
      expect(entry2.summary).to eq CGI.unescapeHTML(@entry2.summary)
      expect(entry2.published).to eq @entry2.published
      expect(entry2.guid).to eq @entry2.guid
    end

    it 'ignores entry if it is received again' do
      # Create an entry for feed @feed with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry_before = FactoryBot.create :entry, feed_id: @feed.id, title: 'Original title',
                                        url: 'http://original.url.com', author: 'Original author',
                                        content: 'Original content', summary: 'Original summary',
                                        published: Time.zone.parse('2013-01-01T00:00:00'), guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid. It will be ignored
      FeedClient.fetch @feed

      # After fetching, entry should be unchanged
      entry_after = Entry.find_by guid: entry_before.guid, feed_id: entry_before.feed_id
      expect(entry_after.feed_id).to eq entry_before.feed_id
      expect(entry_after.title).to eq entry_before.title
      expect(entry_after.url).to eq entry_before.url
      expect(entry_after.author).to eq entry_before.author
      expect(entry_after.summary).to eq CGI.unescapeHTML(entry_before.summary)
      expect(entry_after.guid).to eq entry_before.guid
      expect(entry_after.published).to eq entry_before.published
    end

    it 'saves entry if another one with the same guid but from a different feed is already in the database' do
      feed2 = FactoryBot.create :feed
      # Create an entry for feed feed2 with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry = FactoryBot.create :entry, feed_id: feed2.id, title: 'Original title',
                                 url: 'http://original.url.com/', author: 'Original author',
                                 content: 'Original content', summary: '<p>Original summary</p>',
                                 published: Time.zone.parse('2013-01-01T00:00:00'),
                                 guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid but different feed. Both entries
      # should be treated as different entities.
      FeedClient.fetch @feed

      # After fetching, entry should remain untouched
      entry.reload
      expect(entry.feed_id).to eq feed2.id
      expect(entry.title).to eq 'Original title'
      expect(entry.url).to eq 'http://original.url.com/'
      expect(entry.author).to eq 'Original author'
      expect(entry.summary).to eq '<p>Original summary</p>'
      expect(entry.published).to eq Time.zone.parse('2013-01-01T00:00:00')
      expect(entry.guid).to eq @entry1.guid

      # the fetched entry should be saved in the database as well
      fetched_entry = Entry.find_by guid: @entry1.guid, feed_id: @feed.id
      expect(fetched_entry.feed_id).to eq @feed.id
      expect(fetched_entry.title).to eq @entry1.title
      expect(fetched_entry.url).to eq @entry1.url
      expect(fetched_entry.author).to eq @entry1.author
      expect(fetched_entry.summary).to eq CGI.unescapeHTML(@entry1.summary)
      expect(fetched_entry.published).to eq @entry1.published
      expect(fetched_entry.guid).to eq @entry1.guid
    end

    it 'retrieves the feed title and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.title).to eq @feed_title
    end

    it 'retrieves the feed URL and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      expect(@feed.url).to eq @feed_url
    end
  end

  context 'Itunes feed autodiscovery' do

    it 'updates fetch_url of the feed with autodiscovery full URL' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
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
      feed = FactoryBot.create :feed, title: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link href="#{feed_path}" title="publicadas" type="application/rss+xml" rel="alternate">
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
      feed = FactoryBot.create :feed, title: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link href="#{feed_fetch_url_relative}" title="publicadas" type="application/rss+xml" rel="alternate">
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
      feed_fetch_url_relative = '//webpage.com/feed'
      feed_fetch_url_absolute = 'https://webpage.com/feed'
      feed_url = 'https://webpage.com'
      feed = FactoryBot.create :feed, title: feed_url, fetch_url: feed_url

      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link href="#{feed_fetch_url_relative}" title="publicadas" type="application/rss+xml" rel="alternate">
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

    it 'fetches feed' do
      feed_url = 'http://webpage.com/feed'
      webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_xml = <<FEED_XML
<?xml version='1.0' encoding='UTF-8'?>
<?xml-stylesheet type='text/xsl' href='http://meneame.feedsportal.com/xsl/es/rss.xsl'?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:wfw="http://wellformedweb.org/CommentAPI/" xmlns:media="http://search.yahoo.com/mrss/" xmlns:meneame="http://meneame.net/faq-es.php" version="2.0">
  <channel>
    <atom:link href="http://www.meneame.net/rss2.php" rel="self" type="application/rss+xml"/>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>Sitio colaborativo de publicación y comunicación entre blogs</description>
    <language>es</language>
    <pubDate>Wed, 11 Dec 2013 07:20:04 GMT</pubDate>
    <lastBuildDate>Wed, 11 Dec 2013 07:20:04 GMT</lastBuildDate>
    <ttl>10</ttl>
    <image>
      <title>Menéame: publicadas</title>
      <url>http://mnmstatic.net/img/mnm/eli-rss.png</url>
      <link>http://www.meneame.net</link>
    </image>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <category domain="">corrupta</category>
      <category domain="">mafia</category>
      <category domain="">política</category>
      <category domain="">chiringuito</category>
      <category domain="">ee.uu</category>
      <pubDate>#{@entry1.published}</pubDate>
      <comments>http://www.meneame.net/story/mafia-despilfarradora-corrupta-no-esta-dispuesta-tocar-nada</comments>
      <guid isPermaLink="false">#{@entry1.guid}</guid>
      <wfw:commentRss>http://www.meneame.net/comments_rss2.php?id=2073682</wfw:commentRss>
      <dc:creator>inconformistadesdeel67</dc:creator>
      <media:thumbnail url="http://mnmstatic.net/cache/1f/a4/thumb-2073682.jpg" width="60" height="60"/>
      <meneame:link_id>2073682</meneame:link_id>
      <meneame:status>published</meneame:status>
      <meneame:user>inconformistadesdeel67</meneame:user>
      <meneame:votes>116</meneame:votes>
      <meneame:negatives>11</meneame:negatives>
      <meneame:karma>666</meneame:karma>
      <meneame:comments>15</meneame:comments>
      <meneame:url>http://www.espiaenelcongreso.com/2013/12/09/la-mafia-despilfarradora-y-corrupta-no-esta-dispuesta-a-tocar-nada-que-afecte-a-su-chiringuito/</meneame:url>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      # First fetch the webpage; then, when fetching the actual feed URL, return an RSS 2.0 XML with one entry
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
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

      feed_xml = <<FEED_XML
<?xml version='1.0' encoding='UTF-8'?>
<?xml-stylesheet type='text/xsl' href='http://meneame.feedsportal.com/xsl/es/rss.xsl'?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:wfw="http://wellformedweb.org/CommentAPI/" xmlns:media="http://search.yahoo.com/mrss/" xmlns:meneame="http://meneame.net/faq-es.php" version="2.0">
  <channel>
    <atom:link href="http://www.meneame.net/rss2.php" rel="self" type="application/rss+xml"/>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>Sitio colaborativo de publicación y comunicación entre blogs</description>
    <language>es</language>
    <pubDate>Wed, 11 Dec 2013 07:20:04 GMT</pubDate>
    <lastBuildDate>Wed, 11 Dec 2013 07:20:04 GMT</lastBuildDate>
    <ttl>10</ttl>
    <image>
      <title>Menéame: publicadas</title>
      <url>http://mnmstatic.net/img/mnm/eli-rss.png</url>
      <link>http://www.meneame.net</link>
    </image>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <category domain="">corrupta</category>
      <category domain="">mafia</category>
      <category domain="">política</category>
      <category domain="">chiringuito</category>
      <category domain="">ee.uu</category>
      <pubDate>#{@entry1.published}</pubDate>
      <comments>http://www.meneame.net/story/mafia-despilfarradora-corrupta-no-esta-dispuesta-tocar-nada</comments>
      <guid isPermaLink="false">#{@entry1.guid}</guid>
      <wfw:commentRss>http://www.meneame.net/comments_rss2.php?id=2073682</wfw:commentRss>
      <dc:creator>inconformistadesdeel67</dc:creator>
      <media:thumbnail url="http://mnmstatic.net/cache/1f/a4/thumb-2073682.jpg" width="60" height="60"/>
      <meneame:link_id>2073682</meneame:link_id>
      <meneame:status>published</meneame:status>
      <meneame:user>inconformistadesdeel67</meneame:user>
      <meneame:votes>116</meneame:votes>
      <meneame:negatives>11</meneame:negatives>
      <meneame:karma>666</meneame:karma>
      <meneame:comments>15</meneame:comments>
      <meneame:url>http://www.espiaenelcongreso.com/2013/12/09/la-mafia-despilfarradora-y-corrupta-no-esta-dispuesta-a-tocar-nada-que-afecte-a-su-chiringuito/</meneame:url>
    </item>
  </channel>
</rss>
FEED_XML
      allow(feed_xml).to receive(:headers).and_return({})

      old_feed = FactoryBot.create :feed, fetch_url: feed_url
      new_feed = FactoryBot.create :feed

      # First fetch the webpage; then, when fetching the actual feed URL, return an Atom XML with one entry
      allow(RestClient).to receive :get do |url|
        if url==feed_url
          feed_xml
        elsif url==new_feed.url
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
  <link href="#{rss_url}" title="publicadas" type="application/rss+xml" rel="alternate">
  <link href="#{atom_url}" title="publicadas" type="application/rss+xml" rel="alternate">
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
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

      expect(@feed.fetch_url).not_to eq rss_url
      FeedClient.fetch @feed, perform_autodiscovery: true
      @feed.reload
      expect(@feed.fetch_url).to eq rss_url
    end

  end

end