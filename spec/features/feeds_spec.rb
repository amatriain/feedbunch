require 'spec_helper'

describe 'feeds' do
  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true
  end

  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
    current_path.should eq new_user_session_path
  end

  context 'automatically closing notices and alerts' do

    before :each do
      @user = FactoryGirl.create :user
    end

    it 'closes rails notices after 5 seconds', js: true do
      login_user_for_feature @user
      page.should have_css 'div#notice'
      sleep 5
      page.should_not have_css 'div#notice'
    end

    it 'closes rails alerts after 5 seconds', js: true do
      visit new_user_session_path
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'wrong password'
      click_on 'Sign in'

      page.should have_css 'div#alert'
      sleep 5
      page.should_not have_css 'div#alert'
    end

    it 'closes Devise errors after 5 seconds', js: true do
      visit new_user_registration_path
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'password'
      fill_in 'Confirm password', with: 'different password'
      click_on 'Sign up'

      page.should have_css 'div#devise-error'
      sleep 5
      page.should_not have_css 'div#devise-error'
    end
  end

  context 'subscription to feeds' do

    before :each do
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: @feed2.fetch_url
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      page.should have_css "ul#sidebar li#feed-#{@feed1.id}"
      page.should have_css "ul#sidebar li#feed-#{@feed2.id}.active"
      # The entries for the just subscribed feed should be visible
      page.should have_content entry.title
    end

    it 'subscribes to a feed already in the database, given the website URL', js: true do
      # User is not yet subscribed to @feed2
      entry = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << entry

      find('#add-subscription').click
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: @feed2.url
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      page.should have_css "ul#sidebar li#feed-#{@feed1.id}"
      page.should have_css "ul#sidebar li#feed-#{@feed2.id}.active"
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: url_slash
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      page.should have_css "ul#sidebar li#feed-#{@feed1.id}"
      page.should have_css "ul#sidebar li#feed-#{feed.id}.active"
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: url_no_slash
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      page.should have_css "ul#sidebar li#feed-#{@feed1.id}"
      page.should have_css "ul#sidebar li#feed-#{feed.id}.active"
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: url_no_scheme
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      page.should have_css "ul#sidebar li#feed-#{@feed1.id}"
      page.should have_css "ul#sidebar li#feed-#{feed.id}.active"
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: fetch_url
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      within 'ul#sidebar li#folder-all ul#feeds-all' do
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: webpage_url
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      within 'ul#sidebar li#folder-all ul#feeds-all' do
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: url_no_schema
        find('#subscribe-submit').click
      end

      # Both the old and new feeds should be there, the new feed should be selected
      within 'ul#sidebar li#folder-all ul#feeds-all' do
        page.should have_content @feed1.title
        within 'li.active' do
          page.should have_content feed_title
        end
      end
      # The entries for the just subscribed feed should be visible
      page.should have_content entry_title
    end

    it 'unsubscribes from a feed'

    it 'shows an alert if there is a problem subscribing to a feed', js: true do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      # Try to subscribe to feed (already in the database, for simplicity)
      find('#add-subscription').click
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: webpage_url
        find('#subscribe-submit').click
      end

      # Try to subscribe to feed again submitting the URL without scheme
      find('#add-subscription').click
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: webpage_url
        find('#subscribe-submit').click
      end

      # Try to subscribe to feed again submitting the URL without scheme
      find('#add-subscription').click
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
      within '#subscribe-feed-popup' do
        fill_in 'Feed', with: url_no_schema
        find('#subscribe-submit').click
      end

      # Try to subscribe to feed again submitting the URL without scheme
      find('#add-subscription').click
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

  context 'folders and feeds' do

    before :each do
      @user = FactoryGirl.create :user

      @folder1 = FactoryGirl.build :folder, user_id: @user.id
      @folder2 = FactoryGirl.create :folder
      @user.folders << @folder1

      @feed1 = FactoryGirl.build :feed
      @feed2 = FactoryGirl.build :feed
      @user.feeds << @feed1 << @feed2
      @folder1.feeds << @feed1

      @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed1.entries << @entry1_1 << @entry1_2
      @feed2.entries << @entry2_1 << @entry2_2

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows only folders that belong to the user' do
      page.should have_content @folder1.title
      page.should_not have_content @folder2.title
    end

    it 'shows an All Subscriptions folder with all feeds subscribed to', js: true do
      within 'ul#sidebar' do
        page.should have_content 'All subscriptions'

        within 'li#folder-all' do
          page.should have_css "a[data-target='#feeds-all']"

          # "All feeds" folder should be closed (class "in" not present)
          page.should_not have_css 'ul#feeds-all.in'

          # Open "All feeds" folder (should acquire class "in")
          find("a[data-target='#feeds-all']").click
          page.should have_css 'ul#feeds-all.in'

          # Should have all the feeds inside
          within 'ul#feeds-all' do
            page.should have_css "li#feed-#{@feed1.id}"
            page.should have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'shows folders containing their respective feeds', js: true do
      within 'ul#sidebar' do
        page.should have_content @folder1.title

        within "li#folder-#{@folder1.id}" do
          page.should have_css "a[data-target='#feeds-#{@folder1.id}']"

          # Folder should be closed (class "in" not present)
          page.should_not have_css "ul#feeds-#{@folder1.id}.in"

          # Open folder (should acquire class "in")
          find("a[data-target='#feeds-#{@folder1.id}']").click
          page.should have_css "ul#feeds-#{@folder1.id}.in"

          # Should have inside only those feeds associated to the folder
          within "ul#feeds-#{@folder1.id}" do
            page.should have_css "li#feed-#{@feed1.id}"
            page.should_not have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'shows entries for a feed in the All Subscriptions folder', js: true do
      within 'ul#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        # click on feed
        find("li#feed-#{@feed2.id} > a").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
      page.should_not have_content @entry1_1.title
      page.should_not have_content @entry1_2.title
    end

    it 'shows entries for a feed inside a user folder', js: true do
      within "ul#sidebar li#folder-#{@folder1.id}" do
        # Open folder @folder1
        find("a[data-target='#feeds-#{@folder1.id}']").click

        # Click on feed
        find("li#feed-#{@feed1.id} > a").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows a link to read entries for all subscriptions inside the All Subscriptions folder', js: true do
      within 'ul#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        page.should have_css 'li#folder-all-all-feeds'

        # Click on link to read all feeds
        find('li#folder-all-all-feeds > a').click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
    end

    it 'shows a link to read all entries for all subscriptions inside a folder', js: true do
      # Add a second feed inside @folder1
      feed3 = FactoryGirl.create :feed
      @user.feeds << feed3
      @folder1.feeds << feed3
      entry3_1 = FactoryGirl.build :entry, feed_id: feed3.id
      entry3_2 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry3_1 << entry3_2

      within "ul#sidebar li#folder-#{@folder1.id}" do
        # Open folder
        find("a[data-target='#feeds-#{@folder1.id}']").click

        page.should have_css "li#folder-#{@folder1.id}-all-feeds"

        # Click on link to read all feeds
        find("li#folder-#{@folder1.id}-all-feeds > a").click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content entry3_1.title
      page.should have_content entry3_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows an alert if the feed clicked has no entries', js: true do
      feed3 = FactoryGirl.create :feed
      @user.feeds << feed3
      visit feeds_path
      read_feed feed3.id

      # A "no entries" alert should be shown
      page.should have_css 'div#no-entries'
      page.should_not have_css 'div#no-entries.hidden', visible: false

      # It should close automatically after 5 seconds
      sleep 5
      page.should have_css 'div#no-entries.hidden', visible: false
    end

    it 'shows an alert if there is a problem loading a feed', js: true do
      User.any_instance.stub(:feeds).and_raise StandardError.new
      # Try to read feed
      read_feed @feed1.id

      # A "problem loading feed" alert should be shown
      page.should have_css 'div#problem-loading'
      page.should_not have_css 'div#problem-loading.hidden', visible: false

      # It should close automatically after 5 seconds
      sleep 5
      page.should have_css 'div#problem-loading.hidden', visible: false
    end

    it 'adds a feed to a new folder'

    it 'adds a feed to an existing folder'

    it 'removes a feed from a folder'

    it 'totally removes a folder when it has no feeds under it'
  end

  context 'refresh' do

    before :each do
      @user = FactoryGirl.create :user
      @feed1 = FactoryGirl.create :feed
      @user.feeds << @feed1
      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1

      login_user_for_feature @user
      visit feeds_path
      read_feed @feed1.id
    end

    it 'disables refresh button until a feed is selected', js: true do
      visit feeds_path
      page.should have_css 'a#refresh-feed.disabled'
    end

    it 'enables refresh button when a feed is selected', js: true do
      page.should_not have_css 'a#refresh-feed.disabled'
      page.should have_css 'a#refresh-feed'
    end

    it 'refreshes a single feed', js: true do
      # Page should have current entries for the feed
      page.should have_content @entry1.title

      # Refresh feed
      entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
      FeedClient.should_receive(:fetch).with @feed1.id
      @feed1.entries << entry2
      find('a#refresh-feed').click

      # Page should have the new entries for the feed
      page.should have_content @entry1.title
      page.should have_content entry2.title
    end

    it 'refreshes all subscribed feeds', js: true do
      feed2 = FactoryGirl.create :feed
      @user.feeds << feed2
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry2

      visit feeds_path
      # Click on "Read all subscriptions" within the "All subscriptions" folder
      within 'ul#sidebar li#folder-all' do
        # Open "All subscriptions" folder
        find("a[data-target='#feeds-all']").click
        # Click on "Read all subscriptions"
        find('li#folder-all-all-feeds > a').click
      end

      # Page should have current entries for the two feeds
      page.should have_content @entry1.title
      page.should have_content entry2.title

      # Refresh feed
      entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << entry3
      entry4 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry4
      FeedClient.should_receive(:fetch).with @feed1.id
      FeedClient.should_receive(:fetch).with feed2.id
      find('a#refresh-feed').click

      # Page should have the new entries for the feed
      page.should have_content @entry1.title
      page.should have_content entry2.title
      page.should have_content entry3.title
      page.should have_content entry4.title
    end

    it 'refreshes all subscribed feeds inside a folder', js: true do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed2 = FactoryGirl.create :feed
      @user.feeds << feed2
      folder.feeds << @feed1 << feed2
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry2

      visit feeds_path
      # Click on "Read all subscriptions" within the folder
      within "ul#sidebar li#folder-#{folder.id}" do
        # Open folder
        find("a[data-target='#feeds-#{folder.id}']").click
        # Click on "Read all subscriptions"
        find("li#folder-#{folder.id}-all-feeds > a").click
      end

      # Page should have current entries for the two feeds
      page.should have_content @entry1.title
      page.should have_content entry2.title

      # Refresh feed
      entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << entry3
      entry4 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry4
      FeedClient.should_receive(:fetch).with @feed1.id
      FeedClient.should_receive(:fetch).with feed2.id
      find('a#refresh-feed').click

      # Page should have the new entries for the feed
      page.should have_content @entry1.title
      page.should have_content entry2.title
      page.should have_content entry3.title
      page.should have_content entry4.title
    end

    it 'shows an alert if there is a problem refreshing a feed', js: true do
      FeedClient.stub(:fetch).and_raise ActiveRecord::RecordNotFound.new
      # Refresh feed
      find('a#refresh-feed').click

      # A "problem refreshing feed" alert should be shown
      page.should have_css 'div#problem-refreshing'
      page.should_not have_css 'div#problem-refreshing.hidden', visible: false

      # It should close automatically after 5 seconds
      sleep 5
      page.should have_css 'div#problem-refreshing.hidden', visible: false
    end
  end

  context 'entries' do

    before :each do
      @user = FactoryGirl.create :user
      @feed = FactoryGirl.create :feed
      @user.feeds << @feed
      @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << @entry1 << @entry2

      login_user_for_feature @user
      visit feeds_path
      read_feed @feed.id
    end

    it 'opens an entry', js: true do
      within 'ul#feed-entries' do
        # Entry summary should not be visible
        page.should_not have_content @entry1.summary

        # Open entry
        find("li#entry-#{@entry1.id} > a").click

        # Summary should appear
        page.should have_content @entry1.summary
      end
    end

    it 'closes other entries when opening an entry', js: true do
      within 'ul#feed-entries' do
        # Open first entry, give it some time for open animation
        find("li#entry-#{@entry1.id} > a").click
        sleep 1

        # Only summary of first entry should be visible
        page.should have_content @entry1.summary
        page.should_not have_content @entry2.summary

        # Open second entry, give it some time for open animation
        find("li#entry-#{@entry2.id} > a").click
        sleep 1

        # Only summary of second entry should be visible
        page.should_not have_content @entry1.summary
        page.should have_content @entry2.summary
      end
    end

    it 'marks as read an entry when opening it'

    it 'marks all entries as read'

    it 'marks an entry as unread'

  end
end