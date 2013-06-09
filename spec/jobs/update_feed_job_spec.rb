require 'spec_helper'

describe UpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed.id

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
end