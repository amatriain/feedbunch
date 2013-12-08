require 'spec_helper'

describe UpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
    FeedClient.stub :fetch
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed, anything

    UpdateFeedJob.perform @feed.id
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

    UpdateFeedJob.perform @feed.id

    # Unread count should be corrected
    user.feed_unread_count(@feed).should eq 1
  end

  it 'unschedules updates if the feed has been deleted when the job runs' do
    @feed.destroy
    UpdateFeedJob.should_receive(:unschedule_feed_updates).with @feed.id
    FeedClient.should_not_receive :fetch

    UpdateFeedJob.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    FeedClient.should_not_receive :fetch
    @feed.destroy

    UpdateFeedJob.perform @feed.id
  end

  it 'programs a delayed job to start hourly updates' do
    Resque.should_receive(:enqueue_in) do |delay, job_class, args|
      delay.should be_between 0.minutes, 60.minutes
      job_class.should eq ScheduleFeedUpdatesJob
      args.should eq @feed.id
    end

    UpdateFeedJob.schedule_feed_updates @feed.id
  end

  it 'unschedules a job to update a feed' do
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"

    UpdateFeedJob.unschedule_feed_updates @feed.id
  end

  context 'fix schedule' do

    it 'adds missing scheduled feed updates' do
      feed_unscheduled = FactoryGirl.create :feed, created_at: (Time.now - 2.days)
      # @feed has scheduled updates, feed_unscheduled does not
      Resque.stub :get_schedule do |name|
        if name == "update_feed_#{@feed.id}"
          {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
        else
          nil
        end
      end

      # A job to schedule updates for feed_unscheduled should be enqueued to be run in the next hour
      Resque.should_receive(:enqueue_in).once do |delay, job_class, args|
        delay.should be_between 0.minutes, 60.minutes
        job_class.should eq ScheduleFeedUpdatesJob
        args.should eq feed_unscheduled.id
      end

      UpdateFeedJob.perform @feed.id
    end

    it 'does nothing for existing feed updates' do
      feed_scheduled = FactoryGirl.create :feed
      # @feed and feed_scheduled have scheduled updates
      Resque.stub :get_schedule do |name|
        if name == "update_feed_#{@feed.id}"
          {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
        elsif name == "update_feed_#{feed_scheduled.id}"
          {"class"=>"UpdateFeedJob", "args"=>feed_scheduled.id, "every"=>"1h"}
        end
      end

      # No job to schedule updates should be enqueued
      Resque.should_not_receive :enqueue_in

      UpdateFeedJob.perform @feed.id
    end

    it 'does nothing for feeds created less than 1h30m ago' do
      feed_recent = FactoryGirl.create :feed, created_at: (Time.now - 30.minutes)
      # @feed has scheduled updates. feed_recent does not, but it has been created less than 90 minutes ago.
      Resque.stub :get_schedule do |name|
        if name == "update_feed_#{@feed.id}"
          {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
        else
          nil
        end
      end

      # No job to schedule updates should be enqueued
      Resque.should_not_receive :enqueue_in

      UpdateFeedJob.perform @feed.id
    end
  end

end