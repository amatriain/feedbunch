require 'rails_helper'

describe ScheduledUpdateFeedWorker do

  before :each do
    @feed = FactoryBot.create :feed
  end

  it 'updates feed when the job runs' do
    expect(FeedClient).to receive(:fetch).with @feed

    ScheduledUpdateFeedWorker.new.perform @feed.id
  end

  it 'recalculates unread entries count in feed' do
    # user is subscribed to @feed with 1 entry
    user = FactoryBot.create :user

    entry = FactoryBot.build :entry, feed_id: @feed.id
    @feed.entries << entry

    user.subscribe @feed.fetch_url

    # @feed has an incorrect unread entry count of 10 for user
    feed_subscription = FeedSubscription.find_by user_id: user.id, feed_id: @feed.id
    feed_subscription.update unread_entries: 10

    ScheduledUpdateFeedWorker.new.perform @feed.id

    # Unread count should be corrected
    expect(user.feed_unread_count(@feed)).to eq 1
  end

  it 'does not schedule next update if the feed has been deleted' do
    @feed.destroy
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_in
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_at

    ScheduledUpdateFeedWorker.new.perform @feed.id
  end

  it 'does not schedule next update if the feed has been marked as unavailable' do
    @feed.update available: false
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_in
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_at

    ScheduledUpdateFeedWorker.new.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    expect(FeedClient).not_to receive :fetch
    @feed.destroy

    ScheduledUpdateFeedWorker.new.perform @feed.id
  end

  context 'adaptative schedule' do

    it 'updates the last_fetched timestamp of the feed when successful' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      expect(@feed.last_fetched).to be_nil
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.last_fetched).to eq date
    end

    it 'decrements a 10% the fetch interval if new entries are fetched' do
      allow(FeedClient).to receive :fetch do
        entry = FactoryBot.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3240 - 60.seconds, 3240 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.reload.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3240 - 60.seconds, 3240 + 60.seconds).inclusive
    end

    it 'increments a 10% the fetch interval if no new entries are fetched' do
      allow(FeedClient).to receive :fetch

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.reload.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'does not set a fetch interval smaller than the configured minimum' do
      min_interval = Feedbunch::Application.config.min_update_interval

      allow(FeedClient).to receive :fetch do
        entry = FactoryBot.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(min_interval - 60.seconds, min_interval + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      @feed.update fetch_interval_secs: 10.minutes
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(min_interval - 60.seconds, min_interval + 60.seconds).inclusive
    end

    it 'does not set a fetch interval greater than the configured maximum' do
      allow(FeedClient).to receive :fetch
      max_interval = Feedbunch::Application.config.max_update_interval

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(max_interval - 60.seconds, max_interval + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      @feed.update fetch_interval_secs: max_interval
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(max_interval - 60.seconds, max_interval + 60.seconds).inclusive
    end

  end

  context 'feed fetch_url is failing' do

    before :each do
      # Stub Time.zone.now so that it returns a fixed date
      @time_now = Time.zone.parse '2000-01-01 01:00:00'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now
    end

    context 'failing for the first time' do

      before :each do
        @feed.update failing_since: nil
        allow(RestClient).to receive(:get).and_raise RestClient::RequestTimeout.new
      end

      it 'marks feed as failing' do
        expect(@feed.failing_since).to be_nil
        ScheduledUpdateFeedWorker.new.perform @feed.id
        expect(@feed.reload.failing_since).to eq @time_now
      end

      it 'does not try to perform autodiscovery' do
        expect(RestClient).to receive(:get).once
        ScheduledUpdateFeedWorker.new.perform @feed.id
      end

      it 'does not change fetch_url' do
        # fetch_url would be changed by autodiscovery. We want to check that autodiscovery is not performed.
        @new_fetch_url = 'http://new.fetch.url.com/'

        @webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{@new_fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
        allow(@webpage_html).to receive(:headers).and_return({})

        allow(RestClient).to receive :get do |url|
          if url == @feed.fetch_url
            raise RestClient::RequestTimeout.new
          elsif url == @feed.url
            @webpage_html
          else
            raise StandardError.new
          end
        end

        old_url = @feed.fetch_url
        ScheduledUpdateFeedWorker.new.perform @feed.id
        expect(@feed.reload.fetch_url).to eq old_url
      end
    end

    context 'failing for less than the configured interval' do

      before :each do
        @autodiscovery_after = Feedbunch::Application.config.autodiscovery_after
        # Feed has been failing for 1 minute less than the configured autodiscovery_after interval
        @failing_since = Time.zone.now + 1.minute - @autodiscovery_after
        @feed.update failing_since: @failing_since
      end

      it 'keeps feed marked as failing' do
        expect(@feed.failing_since).to eq @failing_since
        ScheduledUpdateFeedWorker.new.perform @feed.id
        expect(@feed.reload.failing_since).to eq @failing_since
      end

      it 'does not try to perfom autodiscovery' do
        expect(RestClient).to receive(:get).once
        ScheduledUpdateFeedWorker.new.perform @feed.id
      end

      it 'does not change fetch_url' do
        # fetch_url would be changed by autodiscovery. We want to check that autodiscovery is not performed.
        @new_fetch_url = 'http://new.fetch.url.com/'

        @webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{@new_fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
        allow(@webpage_html).to receive(:headers).and_return({})

        allow(RestClient).to receive :get do |url|
          if url == @feed.fetch_url
            raise RestClient::RequestTimeout.new
          elsif url == @feed.url
            @webpage_html
          else
            raise StandardError.new
          end
        end

        old_url = @feed.fetch_url
        ScheduledUpdateFeedWorker.new.perform @feed.id
        expect(@feed.reload.fetch_url).to eq old_url
      end
    end

    context 'failing for longer than the configured interval' do

      before :each do
        @autodiscovery_after = Feedbunch::Application.config.autodiscovery_after
        # Feed has been failing for 1 hour longer than the configured autodiscovery_after interval
        @failing_since = Time.zone.now - 1.hour - @autodiscovery_after
        @feed.update failing_since: @failing_since
      end

      it 'attempts autodiscovery' do
        expect(RestClient).to receive(:get).once.with @feed.fetch_url, anything
        expect(RestClient).to receive(:get).once.with @feed.url, anything
        ScheduledUpdateFeedWorker.new.perform @feed.id
      end

      context 'autodiscovery successful' do

        before :each do
          @new_fetch_url = 'http://new.fetch.url.com/'
          @new_feed_title = 'new feed title'

          @entry = FactoryBot.build :entry
          @entry.title = 'Silence'
          @entry.url = 'http://xkcd.com/1199/'
          @entry.summary = %{All music is just performances of 4'33" in studios where another band happened to be playing at the time.}
          @entry.published = 'Mon, 15 Apr 2013 04:00:00 -0000'
          @entry.guid = 'http://xkcd.com/1199/'

          @webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{@new_fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
          allow(@webpage_html).to receive(:headers).and_return({})

          @feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@new_feed_title}</title>
  <link href="#{@feed.url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@entry.title}</title>
    <link href="#{@entry.url}" rel="alternate" />
    <updated>#{@entry.published}</updated>
    <id>#{@entry.guid}</id>
    <summary type="html">#{@entry.summary}</summary>
  </entry>
</feed>
FEED_XML
          allow(@feed_xml).to receive(:headers).and_return({})

          # The feed fetch_url is no longer valid. The feed url is still valid, and the new fetch_url can be obtained
          # from the HTML via autodiscovery.
          allow(RestClient).to receive :get do |url|
            if url == @feed.fetch_url
              raise RestClient::RequestTimeout.new
            elsif url == @feed.url
              @webpage_html
            elsif url == @new_fetch_url
              @feed_xml
            else
              raise StandardError.new
            end
          end
        end

        it 'replaces fetch_url with autodiscovered one' do
          expect(@feed.fetch_url).not_to eq @new_fetch_url
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.reload.fetch_url).to eq @new_fetch_url
          expect(@feed.title).to eq @new_feed_title
        end

        it 'fetches feed from new fetch URL' do
          expect(@feed.entries.count).to eq 0
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.entries.count).to eq 1
          expect(@feed.entries.first.title).to eq @entry.title
          expect(@feed.entries.first.url).to eq @entry.url
          expect(@feed.entries.first.guid).to eq @entry.guid
        end

        it 'marks feed as not failing' do
          expect(@feed.failing_since).to eq @failing_since
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.reload.failing_since).to be_nil
        end
      end

      context 'autodiscovery failed' do

        before :each do
          @webpage_html = <<WEBPAGE_HTML
<!DOCTYPE html>
<html>
<head>
  <link rel="feed" href="#{@feed.fetch_url}">
</head>
<body>
  webpage body
</body>
</html>
WEBPAGE_HTML
          allow(@webpage_html).to receive(:headers).and_return({})

          # The feed fetch_url is no longer valid. The feed url is still valid, but attempting to audiscover just
          # returns the failing fetch_url again
          allow(RestClient).to receive :get do |url|
            if url == @feed.fetch_url
              raise RestClient::RequestTimeout.new
            elsif url == @feed.url
              @webpage_html
            else
              raise StandardError.new
            end
          end
        end

        it 'keeps feed marked as failing' do
          expect(@feed.failing_since).to eq @failing_since
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.reload.failing_since).to eq @failing_since
        end

        it 'does not change fetch_url attribute' do
          fetch_url = @feed.fetch_url
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.reload.fetch_url).to eq fetch_url
        end

        it 'does not fetch new entries' do
          entry = FactoryBot.build :entry, feed_id: @feed.id
          @feed.entries << entry

          expect(@feed.entries.count).to eq 1
          ScheduledUpdateFeedWorker.new.perform @feed.id
          expect(@feed.reload.entries.count).to eq 1
          expect(@feed.entries.first).to eq entry
        end
      end
    end
  end

  context 'error handling' do

    it 'increments the fetch interval if the feed server returns an HTTP error status' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the request times out' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::RequestTimeout.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the feed server FQDN cannot be resolved' do
      allow(FeedClient).to receive(:fetch).and_raise SocketError.new('getaddrinfo: Name or service not known')

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the feed server connection times out' do
      allow(FeedClient).to receive(:fetch).and_raise Errno::ETIMEDOUT.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the server refuses the connection' do
      allow(FeedClient).to receive(:fetch).and_raise Errno::ECONNREFUSED.new('Connection refused - connect(2) for "feed.com" port 80')

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the server is unreachable' do
      allow(FeedClient).to receive(:fetch).and_raise Errno::EHOSTUNREACH

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the server resets the connection' do
      allow(FeedClient).to receive(:fetch).and_raise Errno::ECONNRESET

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the feed server response is empty' do
      allow(FeedClient).to receive(:fetch).and_raise EmptyResponseError.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if there is a problem trying to do a feed autodiscovery' do
      allow(FeedClient).to receive(:fetch).and_raise FeedAutodiscoveryError.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if there is a problem trying to fetch a valid feed xml' do
      allow(FeedClient).to receive(:fetch).and_raise FeedFetchError.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the response should be zipped but it is not' do
      allow(FeedClient).to receive(:fetch).and_raise Zlib::GzipFile::Error.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if the response is incorrectly zipped' do
      allow(FeedClient).to receive(:fetch).and_raise Zlib::DataError.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

    it 'increments the fetch interval if a bad HTTP response is received' do
      allow(FeedClient).to receive(:fetch).and_raise Net::HTTPBadResponse.new

      expect(ScheduledUpdateFeedWorker).to receive :perform_in do |in_seconds, feed_id|
        expect(in_seconds).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
        expect(feed_id).to eq @feed.id
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to be_between(3960 - 60.seconds, 3960 + 60.seconds).inclusive
    end

  end

  context 'failing feed' do

    it 'sets failing_since to the current date&time the first time an update fails' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      expect(@feed.failing_since).to be_nil
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.failing_since).to eq date
    end

    it 'sets failing_since to nil when an update runs successfully' do
      allow(FeedClient).to receive :fetch
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      expect(@feed.failing_since).to eq date
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.failing_since).to be_nil
    end

    it 'does not change failing_since the second and sucesive times an update fails successively' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      expect(@feed.failing_since).to eq date2
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.failing_since).to eq date2
    end

    it 'marks feed as unavailable when it has been failing longer than the configured maximum' do
      unavailable_after = Feedbunch::Application.config.unavailable_after
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (unavailable_after + 1.day)

      expect(@feed.available).to be true
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.available).to be false
    end

    it 'does not schedule next update for a feed that has been failing longer than the configured maximum' do
      unavailable_after = Feedbunch::Application.config.unavailable_after
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (unavailable_after + 1.day)

      expect(ScheduledUpdateFeedWorker).not_to receive :perform_in
      expect(ScheduledUpdateFeedWorker).not_to receive :perform_at

      ScheduledUpdateFeedWorker.new.perform @feed.id
    end

    it 'does not mark feed as unavailable when it has been failing a week but the next update is successful' do
      allow(FeedClient).to receive :fetch
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      expect(@feed.available).to be true
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.available).to be true
    end

    it 'does not mark feed as unavailable when it updates successfully' do
      allow(FeedClient).to receive :fetch
      @feed.update failing_since: nil

      expect(@feed.available).to be true
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.reload.available).to be true
    end
  end

  context 'delete old entries' do

    before :each do
      @entries = []
      time_oldest_entry = Time.zone.parse '2000-01-01'
       # Feed has 498 entries
      (1..498).each do |i|
        entry = FactoryBot.build :entry, feed_id: @feed.id, published: time_oldest_entry + i.days
        @feed.entries << entry
        @entries << entry
      end

      @time_now = Time.zone.parse '2050-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now
    end

    it 'does not delete entries if they are under the limit' do
      allow(FeedClient).to receive :fetch do
        entry1 = FactoryBot.build :entry, feed_id: @feed.id, published: @time_now
        entry2 = FactoryBot.build :entry, feed_id: @feed.id, published: @time_now + 1.day
        @feed.entries << entry1 << entry2
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.entries.count).to eq 500
    end

    it 'deletes entries above the entries per feed limit, keeping the newer ones' do
      allow(FeedClient).to receive :fetch do
        (1..5).each do |i|
          entry = FactoryBot.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.entries.count).to eq 500

      # 3 oldest entries should be deleted
      (0..2).each do |i|
        expect(Entry.exists?(@entries[i].id)).to be false
        expect(DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid)).to be true
      end

      # the rest of entries, which are newer, should not be deleted
      (3..497).each do |i|
        expect(Entry.exists?(@entries[i].id)).to be true
        expect(DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid)).to be false
      end
    end

    it 'deletes entries above the per feed limit, keeping newer ones and ignoring already deleted entries' do
      deleted_entry = FactoryBot.build :deleted_entry, feed_id: @feed.id
      @feed.deleted_entries << deleted_entry

      allow(FeedClient).to receive :fetch do
        entry = FactoryBot.build :entry, feed_id: @feed.id, published: @time_now, guid: deleted_entry.guid
        @feed.entries << entry
        (1..5).each do |i|
          entry = FactoryBot.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedWorker.new.perform @feed.id
      expect(@feed.entries.count).to eq 500

      # 3 oldest entries should be deleted
      (0..2).each do |i|
        expect(Entry.exists?(@entries[i].id)).to be false
        expect(DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid)).to be true
      end

      # the rest of entries, which are newer, should not be deleted
      (3..497).each do |i|
        expect(Entry.exists?(@entries[i].id)).to be true
        expect(DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid)).to be false
      end
    end
  end

end