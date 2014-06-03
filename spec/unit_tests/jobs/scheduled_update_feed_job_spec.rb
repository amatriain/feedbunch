require 'spec_helper'

describe ScheduledUpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
    FeedClient.stub :fetch
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed

    ScheduledUpdateFeedJob.perform @feed.id
  end

  it 'recalculates unread entries count in feed' do
    # user is subscribed to @feed with 1 entry
    user = FactoryGirl.create :user

    entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << entry

    user.subscribe @feed.fetch_url

    # @feed has an incorrect unread entry count of 10 for user
    feed_subscription = FeedSubscription.where(user_id: user.id, feed_id: @feed.id).first
    feed_subscription.update unread_entries: 10

    ScheduledUpdateFeedJob.perform @feed.id

    # Unread count should be corrected
    user.feed_unread_count(@feed).should eq 1
  end

  it 'unschedules updates if the feed has been deleted' do
    @feed.destroy
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"
    FeedClient.should_not_receive :fetch

    ScheduledUpdateFeedJob.perform @feed.id
  end

  it 'unschedules updates if the feed has been marked as unavailable' do
    @feed.update available: false
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"
    FeedClient.should_not_receive :fetch

    ScheduledUpdateFeedJob.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    FeedClient.should_not_receive :fetch
    @feed.destroy

    ScheduledUpdateFeedJob.perform @feed.id
  end

  context 'adaptative schedule' do

    it 'updates the last_fetched timestamp of the feed when successful' do
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date

      @feed.last_fetched.should be_nil
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.last_fetched.should eq date
    end

    it 'decrements a 10% the fetch interval if new entries are fetched' do
      FeedClient.stub(:fetch) do
        entry = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3240s'
        config[:every][1].should eq ({first_in: 3240})
      end

      @feed.reload.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3240
    end

    it 'increments a 10% the fetch interval if no new entries are fetched' do
      FeedClient.stub(:fetch)

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.reload.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'does not set a fetch interval smaller than the configured minimum' do
      FeedClient.stub(:fetch) do
        entry = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '900s'
        config[:every][1].should eq ({first_in: 900.seconds})
      end

      @feed.update fetch_interval_secs: 15.minutes
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 15.minutes
    end

    it 'does not set a fetch interval greater than the configured maximum' do
      FeedClient.stub(:fetch)

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '43200s'
        config[:every][1].should eq ({first_in: 12.hours})
      end

      @feed.update fetch_interval_secs: 12.hours
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 12.hours
    end

  end

  context 'error handling' do

    it 'increments the fetch interval if the feed server returns an HTTP error status' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if the feed server FQDN cannot be resolved' do
      FeedClient.stub(:fetch).and_raise SocketError.new('getaddrinfo: Name or service not known')

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if the feed server connection times out' do
      FeedClient.stub(:fetch).and_raise Errno::ETIMEDOUT.new('Connection timed out')

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if the server refuses the connection' do
      FeedClient.stub(:fetch).and_raise Errno::ECONNREFUSED.new('Connection refused - connect(2) for "feed.com" port 80')

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if the feed server response is empty' do
      FeedClient.stub(:fetch).and_raise EmptyResponseError.new

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if there is a problem trying to do a feed autodiscovery' do
      FeedClient.stub(:fetch).and_raise FeedAutodiscoveryError.new

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if there is a problem trying to fetch a valid feed xml' do
      FeedClient.stub(:fetch).and_raise FeedFetchError.new

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

  end

  context 'failing feed' do

    it 'sets failing_since to the current date&time the first time an update fails' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date

      @feed.failing_since.should be_nil
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.failing_since.should eq date
    end

    it 'sets failing_since to nil when an update runs successfully' do
      FeedClient.stub(:fetch)
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      @feed.failing_since.should eq date
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.failing_since.should be_nil
    end

    it 'does not change failing_since the second and sucesive times an update fails successively' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      @feed.failing_since.should eq date2
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.failing_since.should eq date2
    end

    it 'marks feed as unavailable when it has been failing longer than a week' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      @feed.available.should be_true
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.available.should be false
    end

    it 'unschedules updates for a feed when it has been failing longer than a week' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"

      ScheduledUpdateFeedJob.perform @feed.id
    end

    it 'does not mark feed as unavailable when it has been failing a week but the next update is successful' do
      FeedClient.stub :fetch
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      @feed.available.should be_true
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.available.should be_true
    end

    it 'does not mark feed as unavailable when it updates successfully' do
      FeedClient.stub :fetch
      @feed.update failing_since: nil

      @feed.available.should be_true
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.reload.available.should be_true
    end
  end

  context 'delete old entries' do

    before :each do
      @entries = []
      time_oldest_entry = Time.zone.parse '2000-01-01'
       # Feed has 498 entries
      (1..498).each do |i|
        entry = FactoryGirl.build :entry, feed_id: @feed.id, published: time_oldest_entry + i.days
        @feed.entries << entry
        @entries << entry
      end

      @time_now = Time.zone.parse '2050-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return @time_now
    end

    it 'does not delete entries if they are under the limit' do
      FeedClient.stub :fetch do
        entry1 = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now
        entry2 = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + 1.day
        @feed.entries << entry1 << entry2
      end

      @feed.entries.count.should eq 498
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.entries.count.should eq 500
    end

    it 'deletes entries above the entries per feed limit, keeping the newer ones' do
      FeedClient.stub :fetch do
        (1..5).each do |i|
          entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      @feed.entries.count.should eq 498
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.entries.count.should eq 500

      # 3 oldest entries should be deleted
      (0..2).each do |i|
        Entry.exists?(@entries[i].id).should be false
        DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid).should be_true
      end

      # the rest of entries, which are newer, should not be deleted
      (3..497).each do |i|
        Entry.exists?(@entries[i].id).should be_true
        DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid).should be false
      end
    end

    it 'deletes entries above the per feed limit, keeping newer ones and ignoring already deleted entries' do
      deleted_entry = FactoryGirl.build :deleted_entry, feed_id: @feed.id
      @feed.deleted_entries << deleted_entry

      FeedClient.stub :fetch do
        entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now, guid: deleted_entry.guid
        @feed.entries << entry
        (1..5).each do |i|
          entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      @feed.entries.count.should eq 498
      ScheduledUpdateFeedJob.perform @feed.id
      @feed.entries.count.should eq 500

      # 3 oldest entries should be deleted
      (0..2).each do |i|
        Entry.exists?(@entries[i].id).should be false
        DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid).should be_true
      end

      # the rest of entries, which are newer, should not be deleted
      (3..497).each do |i|
        Entry.exists?(@entries[i].id).should be_true
        DeletedEntry.exists?(feed_id: @feed.id, guid: @entries[i].guid).should be false
      end
    end
  end

end