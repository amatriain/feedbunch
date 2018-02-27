require 'rails_helper'

describe FeedClient do
  before :each do
    published = Time.zone.parse('2000-01-01')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return published

    @feed = FactoryBot.create :feed, title: 'Some feed title', url: 'http://some.feed.com'

    @feed_title = 'CRISEI'
    @feed_url = 'http://crisei.blogalia.com/'

    @entry1 = FactoryBot.build :entry
    @entry1.title = 'SIR GAWAIN: GALLARDO Y CALAVERA'
    @entry1.url = 'http://crisei.blogalia.com//historias/74112'
    @entry1.summary = '<p>Hijo de reina hada, aunque el detalle pase por alto en la saga, sobrino del rey Arturo y hermanastro a su pesar del traidor Mordred, escocés de isla pero latino de corazón, el jovial Sir Gawain es el personaje que, sin ser familia directa de Valiente, se convierte en la serie en lo más parecido a un padre, primero, a un hermano mayor, más tarde, y en ocasiones incluso a un atolondrado hermano pequeño.</p>'
    @entry1.published = published
    @entry1.guid = 'http://crisei.blogalia.com//historias/74112'

    @entry2 = FactoryBot.build :entry
    @entry2.title = 'PRÍNCIPE VALIENTE: NUEVA EDICIÓN GIGANTE Y EN COLOR'
    @entry2.url = 'http://crisei.blogalia.com//historias/74115'
    @entry2.summary = '<p>Nueva edición restaurada, y a color, de Príncipe Valiente. A partir de la restauración en blanco y negro de Manuel Caldas y con los colores originales reconstruidos, pero no a partir de los viejos periódicos escaneados.</p>'
    @entry1.published = published
    @entry2.guid = 'http://crisei.blogalia.com//historias/74115'
  end

  context 'ISO-8859-1 encoded feed fetching' do

    before :each do
      feed_file = File.join __dir__, '..', '..', '..', 'attachments', 'iso-8859-1-feed.xml'
      feed_xml = File.read feed_file
      allow(feed_xml).to receive(:headers).and_return({content_type: 'text/html; charset=iso-8859-1'})
      allow(RestClient).to receive(:get).and_return feed_xml
    end

    it 'returns the feed if successful' do
      feed = FeedClient.fetch @feed
      expect(feed).to eq @feed
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
                                 url: 'http://original.url.com', author: 'Original author',
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_path}">
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_fetch_url_relative}">
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_fetch_url_relative}">
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
  <link rel="alternate" type="application/rss+xml" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

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
  <link rel="alternate" type="application/rss+xml" href="#{feed_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
      allow(webpage_html).to receive(:headers).and_return({})

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
      old_feed.reload
      expect(old_feed.entries.count).to eq 1
      expect(old_feed.entries.first.guid).to eq @entry1.guid
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
  <link rel="alternate" type="application/rss+xml" href="#{rss_url}">
  <link rel="alternate" type="application/atom+xml" href="#{atom_url}">
  <link rel="feed" href="#{feed_url}">
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