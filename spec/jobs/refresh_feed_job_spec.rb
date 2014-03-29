require 'spec_helper'

describe RefreshFeedJob do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    FeedClient.stub :fetch
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed

    RefreshFeedJob.perform @user.id, @feed.id
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

    RefreshFeedJob.perform @user.id, @feed.id

    # Unread count should be corrected
    user.feed_unread_count(@feed).should eq 1
  end

  it 'unschedules updates if the feed has been deleted when the job runs' do
    @feed.destroy
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"
    FeedClient.should_not_receive :fetch

    RefreshFeedJob.perform @user.id, @feed.id
  end

  it 'does not update feed if it has been deleted' do
    FeedClient.should_not_receive :fetch
    @feed.destroy

    RefreshFeedJob.perform @user.id, @feed.id
  end

  context 'update refresh_feed_job_status' do

    it 'does not update feed if the user does not exist' do
      # subscribe a second user to the feed so that it is not destroyed when @user unsubscribes
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url
      @user.destroy
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform @user.id, @feed.id
    end

    it 'does not update feed if the user is not subscribed' do
      user2 = FactoryGirl.create :user
      FeedClient.should_not_receive :fetch

      RefreshFeedJob.perform user2.id, @feed.id
    end

    it 'creates refresh_feed_job_status with status RUNNING if the user has none' do
      #PENDING
      @user.refresh_feed_job_statuses.destroy_all
      @user.refresh_feed_job_statuses.should be_blank

      RefreshFeedJob.perform @user.id, @feed.id
      @user.refresh_feed_job_statuses.should_not be_blank
      job_status = @user.refresh_feed_job_statuses.first
      job_status.user_id.should eq @user.id
      job_status.feed_id.should eq @feed.id
      job_status.status.should eq RefreshFeedJobStatus::RUNNING
    end

    it 'does not update feed if refresh_feed_job_status is not RUNNING'

    it 'updates refresh_feed_job_status to SUCCESS if successful'

    it 'updates refresh_feed_job_status to ERROR if an error is raised'
  end

  context 'adaptative schedule' do

    it 'updates the last_fetched timestamp of the feed when successful' do
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date

      @feed.last_fetched.should be_nil
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
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
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

    it 'increments the fetch interval if there is a problem trying to parse the xml response' do
      FeedClient.stub(:fetch).and_raise FeedParseError.new

      Resque.should_receive :set_schedule do |name, config|
        name.should eq "update_feed_#{@feed.id}"
        config[:class].should eq 'ScheduledUpdateFeedJob'
        config[:persist].should be_true
        config[:args].should eq @feed.id
        config[:every][0].should eq '3960s'
        config[:every][1].should eq ({first_in: 3960})
      end

      @feed.fetch_interval_secs.should eq 3600
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.fetch_interval_secs.should eq 3960
    end

  end

  context 'failing feed' do

    it 'sets failing_since to the current date&time the first time an update fails' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date

      @feed.failing_since.should be_nil
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.failing_since.should eq date
    end

    it 'sets failing_since to nil when an update runs successfully' do
      FeedClient.stub(:fetch)
      date = Time.zone.parse '2000-01-01'
      @feed.update failing_since: date

      @feed.failing_since.should eq date
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.failing_since.should be_nil
    end

    it 'does not change failing_since the second and sucesive times an update fails successively' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      date2 = Time.zone.parse '1990-01-01'
      @feed.update failing_since: date2

      @feed.failing_since.should eq date2
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.failing_since.should eq date2
    end

    it 'marks feed as unavailable when it has been failing longer than a week' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      @feed.available.should be_true
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.available.should be_false
    end

    it 'unschedules updates for a feed when it has been failing longer than a week' do
      FeedClient.stub(:fetch).and_raise RestClient::Exception.new
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"

      RefreshFeedJob.perform @user.id, @feed.id
    end

    it 'does not mark feed as unavailable when it has been failing a week but the next update is successful' do
      FeedClient.stub :fetch
      date = Time.zone.parse '2000-01-01'
      ActiveSupport::TimeZone.any_instance.stub(:now).and_return date
      @feed.update failing_since: date - (1.week + 1.day)

      @feed.available.should be_true
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.available.should be_true
    end

    it 'does not mark feed as unavailable when it updates successfully' do
      FeedClient.stub :fetch
      @feed.update failing_since: nil

      @feed.available.should be_true
      RefreshFeedJob.perform @user.id, @feed.id
      @feed.reload.available.should be_true
    end
  end

end