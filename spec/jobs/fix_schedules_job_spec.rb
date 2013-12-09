require 'spec_helper'

describe FixSchedulesJob do

  before :each do
    @feed = FactoryGirl.create :feed
  end

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

    FixSchedulesJob.perform
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

    FixSchedulesJob.perform
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

    FixSchedulesJob.perform
  end
end