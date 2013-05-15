require 'spec_helper'

describe 'subscription to feeds' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1

    login_user_for_feature @user
    visit feeds_path
  end

  it 'shows feeds the user is subscribed to' do
    page.should have_content @feed1.title
  end

  it 'does not show feeds the user is not subscribed to' do
    page.should_not have_content @feed2.title
  end

  it 'subscribes to a feed already in the database, given the feed URL', js: true do
    # User is not yet subscribed to @feed2
    entry = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << entry

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: @feed2.fetch_url
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']"
    page.should have_css "#sidebar li.active > a[data-feed-id='#{@feed2.id}']"
    # The entries for the just subscribed feed should be visible
    page.should have_content entry.title
  end

  it 'subscribes to a feed already in the database, given the website URL', js: true do
    # User is not yet subscribed to @feed2
    entry = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << entry

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: @feed2.url
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']"
    page.should have_css "#sidebar li.active > a[data-feed-id='#{@feed2.id}']"
    # The entries for the just subscribed feed should be visible
    page.should have_content entry.title
  end

  it 'subscribes to a feed already in the database, given the website URL with an added trailing slash', js: true do
    # User is not yet subscribed to feed
    website_url = 'http://some.website'
    url_slash = 'http://some.website/'
    feed = FactoryGirl.create :feed, url: website_url
    entry = FactoryGirl.build :entry, feed_id: feed.id
    feed.entries << entry

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_slash
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']"
    page.should have_css "#sidebar li.active > a[data-feed-id='#{feed.id}']"
    # The entries for the just subscribed feed should be visible
    page.should have_content entry.title
  end

  it 'subscribes to a feed already in the database, given the website URL missing a trailing slash', js: true do
    # User is not yet subscribed to feed
    website_url = 'http://some.website/'
    url_no_slash = 'http://some.website'
    feed = FactoryGirl.create :feed, url: website_url
    entry = FactoryGirl.build :entry, feed_id: feed.id
    feed.entries << entry

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_slash
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']"
    page.should have_css "#sidebar li.active > a[data-feed-id='#{feed.id}']"
    # The entries for the just subscribed feed should be visible
    page.should have_content entry.title
  end

  it 'subscribes to a feed already in the database, given the website URL without URI scheme', js: true do
    # User is not yet subscribed to feed
    website_url = 'http://some.website'
    url_no_scheme = 'some.website'
    feed = FactoryGirl.create :feed, url: website_url
    entry = FactoryGirl.build :entry, feed_id: feed.id
    feed.entries << entry

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_scheme
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    page.should have_css "#sidebar li > a[data-feed-id='#{@feed1.id}']"
    page.should have_css "#sidebar li.active > a[data-feed-id='#{feed.id}']"
    # The entries for the just subscribed feed should be visible
    page.should have_content entry.title
  end

  it 'subscribes to a feed not in the database, given the feed URL', js: true do
    # Fetching a feed returns a mock response
    fetch_url = 'http://some.fetch.url'
    feed_title = 'new feed title'
    entry_title = 'some entry title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>http://xkcd.com</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{DateTime.new}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}
    RestClient.stub get: feed_xml

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: fetch_url
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    within '#sidebar li#folder-all ul#feeds-all' do
      page.should have_content @feed1.title
      within 'li.active' do
        page.should have_content feed_title
      end
    end
    # The entries for the just subscribed feed should be visible
    page.should have_content entry_title
  end

  it 'subscribes to a feed not in the database, given the website URL', js: true do
    # Fetching a feed returns an HTML document with feed autodiscovery
    webpage_url = 'http://some.webpage.url'
    fetch_url = 'http://some.webpage.url/feed.php'

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    webpage_html.stub headers: {}

    feed_title = 'new feed title'
    entry_title = 'some entry title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>http://xkcd.com</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{DateTime.new}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}

    RestClient.stub :get do |url|
      if url == webpage_url
        webpage_html
      elsif url == fetch_url
        feed_xml
      end

    end

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: webpage_url
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    within '#sidebar li#folder-all ul#feeds-all' do
      page.should have_content @feed1.title
      within 'li.active' do
        page.should have_content feed_title
      end
    end
    # The entries for the just subscribed feed should be visible
    page.should have_content entry_title
  end

  it 'subscribes to a feed not in the database, given the website URL without scheme', js: true do
    # Fetching a feed returns an HTML document with feed autodiscovery
    webpage_url = 'http://some.webpage.url'
    url_no_schema = 'some.webpage.url'
    fetch_url = 'http://some.webpage.url/feed.php'

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    webpage_html.stub headers: {}

    feed_title = 'new feed title'
    entry_title = 'some entry title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>http://xkcd.com</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{entry_title}</title>
      <link>http://xkcd.com/1203/</link>
      <description>entry summary</description>
      <pubDate>#{DateTime.new}</pubDate>
      <guid>http://xkcd.com/1203/</guid>
    </item>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}

    RestClient.stub :get do |url|
      if url == webpage_url
        webpage_html
      elsif url == fetch_url
        feed_xml
      end

    end

    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_schema
      find('#subscribe-submit').click
    end

    # Both the old and new feeds should be there, the new feed should be selected
    within '#sidebar li#folder-all ul#feeds-all' do
      page.should have_content @feed1.title
      within 'li.active' do
        page.should have_content feed_title
      end
    end
    # The entries for the just subscribed feed should be visible
    page.should have_content entry_title
  end

  it 'shows an alert if there is a problem subscribing to a feed', js: true do
    User.any_instance.stub(:feeds).and_raise StandardError.new
    # Try to subscribe to feed (already in the database, for simplicity)
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: @feed2.fetch_url
      find('#subscribe-submit').click
    end

    # A "problem subscribing to feed" alert should be shown
    page.should have_css 'div#problem-subscribing'
    page.should_not have_css 'div#problem-subscribing.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#problem-subscribing.hidden', visible: false
  end

  it 'shows an alert if the user is already subscribed to the feed', js: true do
    # Try to subscribe to feed again
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: @feed1.fetch_url
      find('#subscribe-submit').click
    end

    # A "you're already subscribed to feed" alert should be shown
    page.should have_css 'div#already-subscribed'
    page.should_not have_css 'div#already-subscribed.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#already-subscribed.hidden', visible: false
  end

  it 'shows an alert if the user is already subscribed to the feed and submits the URL with an added trailing slash', js: true do
    # Fetching a feed returns an HTML document with feed autodiscovery
    webpage_url = 'http://some.webpage.url'
    url_slash = 'http://some.webpage.url/'
    fetch_url = 'http://some.webpage.url/feed.php'

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    webpage_html.stub headers: {}

    feed_title = 'new feed title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}

    RestClient.stub :get do |url|
      if url == webpage_url
        webpage_html
      elsif url == fetch_url
        feed_xml
      end

    end

    # Subscribe to feed
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: webpage_url
      find('#subscribe-submit').click
    end

    sleep 1

    # Try to subscribe to feed again submitting the URL without scheme
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_slash
      find('#subscribe-submit').click
    end

    # A "you're already subscribed to feed" alert should be shown
    page.should have_css 'div#already-subscribed'
    page.should_not have_css 'div#already-subscribed.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#already-subscribed.hidden', visible: false
  end

  it 'shows an alert if the user is already subscribed to the feed and submits the URL missing a trailing slash', js: true do
    # Fetching a feed returns an HTML document with feed autodiscovery
    webpage_url = 'http://some.webpage.url/'
    url_no_slash = 'http://some.webpage.url'
    fetch_url = 'http://some.webpage.url/feed.php'

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    webpage_html.stub headers: {}

    feed_title = 'new feed title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}

    RestClient.stub :get do |url|
      if url == webpage_url
        webpage_html
      elsif url == fetch_url
        feed_xml
      end

    end

    # Subscribe to feed
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: webpage_url
      find('#subscribe-submit').click
    end

    sleep 1

    # Try to subscribe to feed again submitting the URL without scheme
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_slash
      find('#subscribe-submit').click
    end

    # A "you're already subscribed to feed" alert should be shown
    page.should have_css 'div#already-subscribed'
    page.should_not have_css 'div#already-subscribed.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#already-subscribed.hidden', visible: false
  end

  it 'shows an alert if the user is already subscribed to the feed and submits the URL without schema', js: true do
    # Fetching a feed returns an HTML document with feed autodiscovery
    webpage_url = 'http://some.webpage.url'
    url_no_schema = 'some.webpage.url'
    fetch_url = 'http://some.webpage.url/feed.php'

    webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="alternate" type="application/atom+xml" href="#{fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
    webpage_html.stub headers: {}

    feed_title = 'new feed title'
    feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{feed_title}</title>
    <link>#{webpage_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
  </channel>
</rss>
FEED_XML
    feed_xml.stub(:headers).and_return {}

    RestClient.stub :get do |url|
      if url == webpage_url
        webpage_html
      elsif url == fetch_url
        feed_xml
      end

    end

    # Subscribe to feed
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_schema
      find('#subscribe-submit').click
    end

    sleep 1

    # Try to subscribe to feed again submitting the URL without scheme
    find('#add-subscription').click
    sleep 1
    within '#subscribe-feed-popup' do
      fill_in 'Feed', with: url_no_schema
      find('#subscribe-submit').click
    end

    # A "you're already subscribed to feed" alert should be shown
    page.should have_css 'div#already-subscribed'
    page.should_not have_css 'div#already-subscribed.hidden', visible: false

    # It should close automatically after 5 seconds
    sleep 5
    page.should have_css 'div#already-subscribed.hidden', visible: false
  end
end
