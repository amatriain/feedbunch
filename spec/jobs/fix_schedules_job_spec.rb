require 'spec_helper'

describe FixSchedulesJob do

  before :each do
    @feed = FactoryGirl.create :feed

    Resque.stub :fetch_schedule do
      {"class"=>"ScheduledUpdateFeedJob", "args"=>@feed.id, "every"=>"3600s"}
    end
  end

  it 'adds missing scheduled feed updates' do
    feed_unscheduled = FactoryGirl.create :feed
    # @feed has scheduled updates, feed_unscheduled does not
    Resque.stub :fetch_schedule do |name|
      if name == "update_feed_#{@feed.id}"
        {"class"=>"ScheduledUpdateFeedJob", "args"=>@feed.id, "every"=>"3600s"}
      else
        nil
      end
    end

    # A job to schedule updates for feed_unscheduled should be enqueued to be run in the next hour
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{feed_unscheduled.id}"
      config[:class].should eq 'ScheduledUpdateFeedJob'
      config[:args].should eq feed_unscheduled.id
      config[:every][0].should eq '3600s'
    end

    FixSchedulesJob.perform
  end

  it 'schedules next update when it should have been scheduled' do
    @feed.update last_fetched: Time.zone.parse('2000-01-01 01:00:00')
    @feed.update fetch_interval_secs: 12.hours

    time_now = Time.zone.parse('2000-01-01 10:00:00')
    ActiveSupport::TimeZone.any_instance.stub(:now).and_return time_now
    Resque.stub :fetch_schedule

    # A job to schedule updates for @feed should be enqueued to be run at 2000-01-01 13:00:00
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'ScheduledUpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{12.hours}s"
      config[:every][1][:first_in].should eq 3.hours
    end

    FixSchedulesJob.perform
  end

  it 'immediately schedules next update if the next update should have been scheduled in the past' do
    @feed.update last_fetched: Time.zone.parse('2000-01-01 01:00:00')
    @feed.update fetch_interval_secs: 12.hours

    time_now = Time.zone.parse('2000-01-02 01:00:00')
    ActiveSupport::TimeZone.any_instance.stub(:now).and_return time_now
    Resque.stub :fetch_schedule

    # A job to schedule updates for @feed should be enqueued to be run immediately
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'ScheduledUpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{12.hours}s"
      config[:every][1][:first_in].should be_between 0.minutes, 15.minutes
    end

    FixSchedulesJob.perform
  end

  it 'schedules next update in the following hour if feed has never been updated' do
    Resque.stub :fetch_schedule

    # A job to schedule updates for @feed should be scheduled sometime during the next hour
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'ScheduledUpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{1.hour}s"
      config[:every][1][:first_in].should be_between 0.minutes, 60.minutes
    end

    @feed.last_fetched.should be_nil
    FixSchedulesJob.perform
  end

  it 'does nothing for existing feed updates' do
    feed_scheduled = FactoryGirl.create :feed
    # @feed and feed_scheduled have scheduled updates
    Resque.stub :fetch_schedule do |name|
      if name == "update_feed_#{@feed.id}"
        {"class"=>"ScheduledUpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
      elsif name == "update_feed_#{feed_scheduled.id}"
        {"class"=>"ScheduledUpdateFeedJob", "args"=>feed_scheduled.id, "every"=>"1h"}
      end
    end

    # No job to schedule updates should be enqueued
    Resque.should_not_receive :set_schedule

    FixSchedulesJob.perform
  end

  it 'does not add a schedule for an unavailable feed' do
    @feed.update available: false
    Resque.stub :fetch_schedule

    Resque.should_not_receive :set_schedule

    FixSchedulesJob.perform
  end
end