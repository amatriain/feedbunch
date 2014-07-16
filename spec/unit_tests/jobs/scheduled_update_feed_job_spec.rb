require 'rails_helper'

describe ScheduledUpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
    allow(FeedClient).to receive :fetch
  end

  it 'updates feed when the job runs' do
    expect(FeedClient).to receive(:fetch).with @feed

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
    expect(user.feed_unread_count(@feed)).to eq 1
  end

  it 'unschedules updates if the feed has been deleted' do
    @feed.destroy
    expect(Resque).to receive(:remove_schedule).with "update_feed_#{@feed.id}"
    expect(FeedClient).not_to receive :fetch

    ScheduledUpdateFeedJob.perform @feed.id
  end

  it 'unschedules updates if the feed has been marked as unavailable' do
    @feed.update available: false
    expect(Resque).to receive(:remove_schedule).with "update_feed_#{@feed.id}"
    expect(FeedClient).not_to receive :fetch

    ScheduledUpdateFeedJob.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    expect(FeedClient).not_to receive :fetch
    @feed.destroy

    ScheduledUpdateFeedJob.perform @feed.id
  end

  context 'adaptative schedule' do

    it 'updates the last_fetched timestamp of the feed when successful' do
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      expect(@feed.last_fetched).to be_nil
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.last_fetched).to eq date
    end

    it 'decrements a 10% the fetch interval if new entries are fetched' do
      allow(FeedClient).to receive(:fetch) do
        entry = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3240s'
        expect(config[:every][1]).to eq ({first_in: 3240})
      end

      expect(@feed.reload.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3240
    end

    it 'increments a 10% the fetch interval if no new entries are fetched' do
      allow(FeedClient).to receive(:fetch)

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.reload.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'does not set a fetch interval smaller than the configured minimum' do
      allow(FeedClient).to receive(:fetch) do
        entry = FactoryGirl.build :entry, feed_id: @feed.id
        @feed.entries << entry
      end

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '600s'
        expect(config[:every][1]).to eq ({first_in: 600.seconds})
      end

      @feed.update fetch_interval_secs: 10.minutes
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 10.minutes
    end

    it 'does not set a fetch interval greater than the configured maximum' do
      allow(FeedClient).to receive(:fetch)

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '21600s'
        expect(config[:every][1]).to eq ({first_in: 6.hours})
      end

      @feed.update fetch_interval_secs: 6.hours
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 6.hours
    end

  end

  context 'error handling' do

    it 'increments the fetch interval if the feed server returns an HTTP error status' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if the feed server FQDN cannot be resolved' do
      allow(FeedClient).to receive(:fetch).and_raise SocketError.new('getaddrinfo: Name or service not known')

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if the feed server connection times out' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::RequestTimeout.new

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if the server refuses the connection' do
      allow(FeedClient).to receive(:fetch).and_raise Errno::ECONNREFUSED.new('Connection refused - connect(2) for "feed.com" port 80')

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if the feed server response is empty' do
      allow(FeedClient).to receive(:fetch).and_raise EmptyResponseError.new

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if there is a problem trying to do a feed autodiscovery' do
      allow(FeedClient).to receive(:fetch).and_raise FeedAutodiscoveryError.new

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

    it 'increments the fetch interval if there is a problem trying to fetch a valid feed xml' do
      allow(FeedClient).to receive(:fetch).and_raise FeedFetchError.new

      expect(Resque).to receive :set_schedule do |name, config|
        expect(name).to eq "update_feed_#{@feed.id}"
        expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
        expect(config[:persist]).to be true
        expect(config[:args]).to eq @feed.id
        expect(config[:every][0]).to eq '3960s'
        expect(config[:every][1]).to eq ({first_in: 3960})
      end

      expect(@feed.fetch_interval_secs).to eq 3600
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.fetch_interval_secs).to eq 3960
    end

  end

  context 'failing feed' do

    it 'sets failing_since to the current date&time the first time an update fails' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date

      expect(@feed.failing_since).to be_nil
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.failing_since).to eq date
    end

    it 'sets failing_since to nil when an update runs successfully' do
      allow(FeedClient).to receive(:fetch)
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      expect(@feed.failing_since).to eq date
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.failing_since).to be_nil
    end

    it 'does not change failing_since the second and sucesive times an update fails successively' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      expect(@feed.failing_since).to eq date2
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.failing_since).to eq date2
    end

    it 'marks feed as unavailable when it has been failing longer than a week' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      expect(@feed.available).to be true
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.available).to be false
    end

    it 'unschedules updates for a feed when it has been failing longer than a week' do
      allow(FeedClient).to receive(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      expect(Resque).to receive(:remove_schedule).with "update_feed_#{@feed.id}"

      ScheduledUpdateFeedJob.perform @feed.id
    end

    it 'does not mark feed as unavailable when it has been failing a week but the next update is successful' do
      allow(FeedClient).to receive :fetch
      date = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      expect(@feed.available).to be true
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.available).to be true
    end

    it 'does not mark feed as unavailable when it updates successfully' do
      allow(FeedClient).to receive :fetch
      @feed.update failing_since: nil

      expect(@feed.available).to be true
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.reload.available).to be true
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
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return @time_now
    end

    it 'does not delete entries if they are under the limit' do
      allow(FeedClient).to receive :fetch do
        entry1 = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now
        entry2 = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + 1.day
        @feed.entries << entry1 << entry2
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedJob.perform @feed.id
      expect(@feed.entries.count).to eq 500
    end

    it 'deletes entries above the entries per feed limit, keeping the newer ones' do
      allow(FeedClient).to receive :fetch do
        (1..5).each do |i|
          entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedJob.perform @feed.id
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
      deleted_entry = FactoryGirl.build :deleted_entry, feed_id: @feed.id
      @feed.deleted_entries << deleted_entry

      allow(FeedClient).to receive :fetch do
        entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now, guid: deleted_entry.guid
        @feed.entries << entry
        (1..5).each do |i|
          entry = FactoryGirl.build :entry, feed_id: @feed.id, published: @time_now + i.days
          @feed.entries << entry
        end
      end

      expect(@feed.entries.count).to eq 498
      ScheduledUpdateFeedJob.perform @feed.id
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