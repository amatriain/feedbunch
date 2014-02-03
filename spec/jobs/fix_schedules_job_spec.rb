require 'spec_helper'

describe FixSchedulesJob do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  it 'adds missing scheduled feed updates' do
    feed_unscheduled = FactoryGirl.create :feed
    # @feed has scheduled updates, feed_unscheduled does not
    Resque.stub :get_schedule do |name|
      if name == "update_feed_#{@feed.id}"
        {"class"=>"UpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
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
      config[:every][1][:first_in].should be_between 0.minutes, 60.minutes
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
    Resque.should_not_receive :set_schedule

    FixSchedulesJob.perform
  end
end