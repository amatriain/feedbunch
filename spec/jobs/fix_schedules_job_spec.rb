require 'spec_helper'

describe FixSchedulesJob do

  before :each do
    @feed = FactoryGirl.create :feed

    Resque.stub :get_schedule do
      {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"3600s"}
    end
  end

  it 'adds missing scheduled feed updates' do
    feed_unscheduled = FactoryGirl.create :feed
    # @feed has scheduled updates, feed_unscheduled does not
    Resque.stub :get_schedule do |name|
      if name == "update_feed_#{@feed.id}"
        {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"3600s"}
      else
        nil
      end
    end

    # A job to schedule updates for feed_unscheduled should be enqueued to be run in the next hour
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{feed_unscheduled.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq feed_unscheduled.id
      config[:every][0].should eq '3600s'
    end

    FixSchedulesJob.perform
  end

  it 'schedules next update when it should have been scheduled' do
    @feed.update last_fetched: DateTime.new(2000, 1, 1, 1)
    @feed.update fetch_interval_secs: 12.hours

    DateTime.stub(:now).and_return DateTime.new(2000, 1, 1, 10)
    Resque.stub :get_schedule

    # A job to schedule updates for @feed should be enqueued to be run at 2000-01-01 13:00:00
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{12.hours}s"
      config[:every][1][:first_in].should eq 3.hours
    end

    FixSchedulesJob.perform
  end

  it 'immediately schedules next update if the next update should have been scheduled in the past' do
    @feed.update last_fetched: DateTime.new(2000, 1, 1, 1)
    @feed.update fetch_interval_secs: 12.hours

    DateTime.stub(:now).and_return DateTime.new(2000, 1, 2, 1)
    Resque.stub :get_schedule

    # A job to schedule updates for @feed should be enqueued to be run immediately
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{12.hours}s"
      config[:every][1][:first_in].should eq 1.second
    end

    FixSchedulesJob.perform
  end

  it 'schedules next update in the following hour if feed has never been updated' do
    Resque.stub :get_schedule

    # A job to schedule updates for @feed should be scheduled sometime during the next hour
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{1.hour}s"
      config[:every][1][:first_in].should be_between 1.minute, 60.minutes
    end

    @feed.last_fetched.should be_nil
    FixSchedulesJob.perform
  end

  it 'sets a default update interval of 1 hour if none is set' do
    @feed.update_column :fetch_interval_secs, nil
    Resque.stub :get_schedule

    # A job to schedule updates for @feed should be scheduled sometime during the next hour
    Resque.should_receive(:set_schedule).once do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every][0].should eq "#{1.hour}s"
    end

    @feed.fetch_interval_secs.should be_nil
    FixSchedulesJob.perform
    @feed.reload.fetch_interval_secs.should eq 1.hour
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
    Resque.should_not_receive :set_schedule

    FixSchedulesJob.perform
  end
end