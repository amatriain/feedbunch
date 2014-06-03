require 'spec_helper'

describe FeedClient do
  before :each do
    @feed = FactoryGirl.create :feed, title: 'Some feed title', url: 'http://some.feed.com'

    @feed_title = 'Menéame: publicadas'
    @feed_url = 'http://www.meneame.net/'

    @entry1 = FactoryGirl.build :entry
    @entry1.title = 'Los correos secretos de Caja Madrid: así celebró Blesa el \'éxito\' de las preferentes'
    @entry1.url = 'http://meneame.feedsportal.com/c/34737/f/639540/s/34adc456/sc/36/l/0L0Smeneame0Bnet0Cstory0Ccorreos0Esecretos0Ecaja0Emadrid0Easi0Ecelebro0Eblesa0Eexito0Epreferentes/story01.htm'
    @entry1.summary = %{&lt;p&gt;Como una fiesta financiera, como un pelotazo empresarial, como un nuevo récord. Así vivió Miguel Blesa, entonces presidente de Caja Madrid, la millonaria emisión de preferentes en 2009, un producto financiero que atrapó a miles de clientes de la entidad y volatilizó sus ahorros. Varios correos del mejor amigo de Aznar en la banca, a los que ha tenido acceso eldiario.es, describen el ambiente de euforia sin vértigo en aquellos días de emisiones millonarias.&lt;/p&gt;}
    @entry1.published = 'Wed, 11 Dec 2013 07:20:04 GMT'
    @entry1.guid = 'http://www.meneame.net/story/correos-secretos-caja-madrid-asi-celebro-blesa-exito-preferentes'

    @entry2 = FactoryGirl.build :entry
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

      feed_xml.stub(:headers).and_return({})
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
                                        published: Time.zone.parse('2013-01-01T00:00:00'), guid: @entry1.guid

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
                                 published: Time.zone.parse('2013-01-01T00:00:00'),
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
      entry.published.should eq Time.zone.parse('2013-01-01T00:00:00')
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

    it 'retrieves the feed URL and saves it in the database' do
      FeedClient.fetch @feed
      @feed.reload
      @feed.url.should eq @feed_url
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
  <link href="#{feed_path}" title="publicadas" type="application/rss+xml" rel="alternate">
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
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

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
  <link href="#{feed_url}" title="publicadas" type="application/rss+xml" rel="alternate">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      webpage_html.stub headers: {}

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
      Feed.exists?(new_feed).should be false
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